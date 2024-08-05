// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
/**
 * @id cpp/drivers/TODO
 * @kind problem
 * @name TODO
 * @description TODO
 * @platform Desktop
 * @feature.area Multiple
 * @impact Insecure Coding Practice
 * @repro.text
 * @owner.email: sdat@microsoft.com
 * @opaqueid CQLD-TODO
 * @problem.severity warning
 * @precision medium
 * @tags correctness
 * @scope domainspecific
 * @query-version v1
 */

import cpp
import semmle.code.cpp.dataflow.new.DataFlow

class RegistryIsolationFunction extends Function {
  RegistryIsolationFunction() {
    this.getName().matches("IoOpenDriverRegistryKey") or
    this.getName().matches("ZwCreateKey") or
    this.getName().matches("ZwCreateKeyTransacted") or
    this.getName().matches("ZwDeleteKey") or
    this.getName().matches("ZwDeleteValueKey") or
    this.getName().matches("ZwOpenKey") or
    this.getName().matches("ZwOpenKeyTransacted") or
    this.getName().matches("ZwOpenKeyEx") or
    this.getName().matches("ZwOpenKeyTransactedEx") or
    this.getName().matches("ZwQueryKey") or
    this.getName().matches("ZwRenameKey") or
    this.getName().matches("ZwSetInformationKey") or
    this.getName().matches("ZwSetValueKey") or
    this.getName().matches("ZwQueryValueKey") or
    this.getName().matches("RtlCreateRegistryKey") or
    this.getName().matches("RtlCheckRegistryKey") or
    this.getName().matches("RtlDeleteRegistryValue") or
    this.getName().matches("RtlWriteRegistryValue") or
    this.getName().matches("RtlQueryRegistryValues") or
    this.getName().matches("RtlQueryRegistryValuesEx")
  }
}

class RegistryIsolationFunctionCall extends FunctionCall {
  RegistryIsolationFunctionCall() { this.getTarget() instanceof RegistryIsolationFunction }
}

/*
 * InitializeObjectAttributes: For second param (PUNICODE_STRING), if fully qualified object name passed, then RootDirectory is NULL.
 * If relative path name to the object directory specified by RootDirectory (not null)
 */

/*
 * OBJECT_ATTRIBUTES->RootDirectory is non-null
 */

module IsolationDataFlowNonNullRootDirConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    exists(FieldAccess fa, VariableAccess va |
      fa.getTarget().getName().matches("RootDirectory") and
      va.getType().toString().matches("%OBJECT_ATTRIBUTES%") and
      va.getParent*() = fa.getParent*() and
      source.asIndirectExpr() = va and
      not exists(Expr assignedValue |
        assignedValue = fa.getTarget().getAnAssignedValue() and
        assignedValue.getParent*() = va.getParent*() and
        assignedValue.getValue().toString().matches("%") // assignedValue only has a value when it's constant
      )
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(FunctionCall f |
      zwCall(f) and
      sink.asIndirectExpr() = f.getAnArgument()
    )
  }
}

module IsolationDataFlowNonNullRootDir = DataFlow::Global<IsolationDataFlowNonNullRootDirConfig>;

/*
 * OBJECT_ATTRIBUTES->RootDirectory is NULL
 */

module IsolationDataFlowNullRootDirConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    exists(FieldAccess fa, VariableAccess va, Expr assignedValue |
      fa.getTarget().getName().matches("RootDirectory") and
      va.getType().toString().matches("%OBJECT_ATTRIBUTES%") and
      va.getParent*() = fa.getParent*() and
      assignedValue = fa.getTarget().getAnAssignedValue() and
      assignedValue.getParent*() = va.getParent*() and
      assignedValue.getValue().toString().matches("%") and // assignedValue only has a value when it's constant
      source.asIndirectExpr() = va
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(FunctionCall f |
      zwCall(f) and
      sink.asIndirectExpr() = f.getAnArgument()
    )
  }
}

module IsolationDataFlowNullRootDir = DataFlow::Global<IsolationDataFlowNullRootDirConfig>;

/*
 * //
 */

module IsolationDataFlowObjectNameConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    exists(FieldAccess fa, VariableAccess va, Expr assignedValue |
      fa.getTarget().getName().matches("ObjectName") and
      va.getType().toString().matches("%OBJECT_ATTRIBUTES%") and
      va.getParent*() = fa.getParent*() and
      source.asIndirectExpr() = va
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(FunctionCall f |
      zwCall(f) and
      sink.asIndirectExpr() = f.getAnArgument()
    )
  }
}

module IsolationDataFlowObjectName = DataFlow::Global<IsolationDataFlowObjectNameConfig>;

/*
 * Allow read access if OBJECT_ATTRIBUTES->ObjectName is initialized with \registry\machine\hardware%
 */

module IsolationDataFlowAllowedRead implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    exists(VariableAccess assignedVal |
      assignedVal.getTarget().getAnAssignedValue().toString().toLowerCase().matches("%") and // TODO \registry\machine\hardware
      source.asIndirectExpr() = assignedVal and
      not assignedVal.getType().toString().matches("%OBJECT_ATTRIBUTES%")
    )
  }

  predicate isAdditionalFlowStep(DataFlow::Node pred, DataFlow::Node succ) {
    exists(VariableAccess va0, VariableAccess va1, FunctionCall fc |
      (
        fc.getTarget().getName().matches("RtlInitUnicodeString") or
        fc.getTarget().getName().matches("RtlUnicodeStringInit ")
      ) and
      fc.getArgument(1) = va1.getParent*() and
      fc.getArgument(0) = va0.getParent*() and
      va0 = succ.asIndirectArgument() and
      va1 = pred.asIndirectArgument()
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(FieldAccess fa, VariableAccess va, Expr assignedValue |
      fa.getTarget().getName().matches("ObjectName") and
      va.getType().toString().matches("%OBJECT_ATTRIBUTES%") and
      va.getParent*() = fa.getParent*() and
      assignedValue = fa.getTarget().getAnAssignedValue() and
      assignedValue.getParent*() = va.getParent*() and
      sink.asIndirectExpr() = assignedValue
    )
  }
}

module AllowedReadFlow = DataFlow::Global<IsolationDataFlowAllowedRead>;

/*
 * If using a Zw* registry function and the OBJECT_ATTRIBUTES passed to it has a non-null RootDirectory
 * whether or not it is a violation depends on where the handle they specify in RootDirectory comes from.
 */

module AllowedRootDirectoryFlowConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    exists(Expr arg, FunctionCall fc |
      (
        fc.getTarget().getName().matches("IoOpenDeviceRegistryKey") or
        fc.getTarget().getName().matches("WdfDeviceOpenRegistryKey") or
        fc.getTarget().getName().matches("WdfFdoInitOpenRegistryKey ") or
        fc.getTarget().getName().matches("CM_Open_DevNode_Key")
      ) and
      arg = fc.getAnArgument() and
      (
        arg.getType().toString().matches("%HANDLE%") or
        arg.getType().toString().matches("%WDFKEY%")
      ) and
      source.asIndirectExpr() = arg
    )
  }

  predicate isSink(DataFlow::Node sink) {
    exists(Expr assignedValue, FieldAccess fa, VariableAccess va |
      fa.getTarget().getName().matches("RootDirectory") and
      va.getType().toString().matches("%OBJECT_ATTRIBUTES%") and
      va.getParent*() = fa.getParent*() and
      assignedValue = fa.getTarget().getAnAssignedValue() and
      assignedValue.getParent*() = va.getParent*() and
      sink.asExpr() = assignedValue
    )
  }
}

module AllowedRootDirectoryFlow = DataFlow::Global<AllowedRootDirectoryFlowConfig>;

predicate rtlViolation(RegistryIsolationFunctionCall f) {
  f.getTarget().getName().matches("Rtl%") and
  // Violation if RelativeTo parameter is NOT RTL_REGISTRY_DEVICEMAP
  exists(MacroInvocation m |
    f.getArgument(0) = m.getExpr() and
    not m.getMacroName().matches("RTL_REGISTRY_DEVICEMAP")
  )
  or
  // Violation if RelativeTo parameter IS RTL_REGISTRY_DEVICEMAP and not doing a READ
  exists(MacroInvocation m |
    f.getArgument(0) = m.getExpr() and
    m.getMacroName().matches("RTL_REGISTRY_DEVICEMAP") and
    not (
      f.getTarget().getName().matches("RtlQueryRegistryValues%") or
      f.getTarget().getName().matches("RtlQueryRegistryValuesEx%") or
      f.getTarget().getName().matches("RtlCheckRegistryKey%")
    )
  )
  // TODO read only OK
}

predicate zwRead(RegistryIsolationFunctionCall f) {
  (
    f.getTarget().getName().matches("ZwQueryKey") or
    f.getTarget().getName().matches("ZwQueryValueKey")
  )
  or
  f.getTarget().getName().matches("Zw%") and
  f.getAnArgument().getType().toString().matches("ACCESS_MASK") and
  exists(MacroInvocation m |
    f.getAnArgument() = m.getExpr() and
    (
      m.getMacroName().matches("KEY_QUERY_VALUE") or
      m.getMacroName().matches("KEY_ENUMERATE_SUB_KEYS") or
      m.getMacroName().matches("KEY_CREATE_LINK") or
      m.getMacroName().matches("KEY_NOTIFY") or
      m.getMacroName().matches("KEY_READ") or
      m.getMacroName().matches("KEY_EXECUTE")
    )
  )
}

predicate zwWrite(RegistryIsolationFunctionCall f) {
  (
    f.getTarget().getName().matches("ZwDeleteKey") or
    f.getTarget().getName().matches("ZwDeleteValueKey") or
    f.getTarget().getName().matches("ZwSetValueKey")
  )
  or
  f.getTarget().getName().matches("Zw%") and
  f.getAnArgument().getType().toString().matches("ACCESS_MASK") and
  not exists(MacroInvocation m |
    f.getAnArgument() = m.getExpr() and
    (
      m.getMacroName().matches("KEY_QUERY_VALUE") or
      m.getMacroName().matches("KEY_ENUMERATE_SUB_KEYS") or
      m.getMacroName().matches("KEY_CREATE_LINK") or
      m.getMacroName().matches("KEY_NOTIFY") or
      m.getMacroName().matches("KEY_READ") or
      m.getMacroName().matches("KEY_EXECUTE")
    )
  )
}

predicate zwCall(RegistryIsolationFunctionCall f) {
  zwRead(f)
  or
  zwWrite(f)
}

from RegistryIsolationFunctionCall f
where
  //Function call is an rtl function violation
  rtlViolation(f)
  or
  // registry violation zw functions ( non-null RootDirectory)
  exists(DataFlow::Node source, DataFlow::Node sink |
    IsolationDataFlowNonNullRootDir::flow(source, sink) and // OBJECT_ATTRIBUTES->RootDirectory is non-null and flow from ObjectAttributes to Zw* function
    // check if the handle passed to Zw* function is not from a valid source
    not exists(DataFlow::Node source2, DataFlow::Node sink2 |
      AllowedRootDirectoryFlow::flow(source2, sink2) and
      source.asExpr().getParent*() = sink2.asExpr().getParent*()
    ) and
    sink.asExpr().getParent*() = f
  )
  or
  exists(
    DataFlow::Node source, DataFlow::Node sink, DataFlow::Node source2, DataFlow::Node sink2,
    Element p1, Element p2
  |
    IsolationDataFlowNullRootDir::flow(source, sink) and // OBJECT_ATTRIBUTES->RootDirectory is NULL and used in a Zw* function
    sink.asExpr().getParent*() = f and
    // a read access is allowed if OBJECT_ATTRIBUTES->ObjectName is initialized with \registry\machine\hardware%
    (
      not AllowedReadFlow::flow(source2, sink2) and // flow from variable assignment to  OBJECT_ATTRIBUTES->ObjectName
      sink2 != source2 and
      // check if source (OBJECT_ATTRIBUTES) and sink2 (OBJECT_ATTRIBUTES->ObjectName) are in the same function call
      p1 = source.asIndirectExpr().getEnclosingStmt().getEnclosingElement() and
      p2 = sink2.asIndirectExpr().getEnclosingStmt().getEnclosingElement() and
      p1 = p2 and
      not zwRead(f)
    )
  )
select f, f.toString()
