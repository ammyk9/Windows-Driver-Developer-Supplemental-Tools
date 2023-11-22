// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
/**
 * @id cpp/drivers/role-type-correctly-used
 * @kind problem
 * @name Incorrect Role Type Use
 * @description A function is declared with a role type but used as an argument in a function that expects a different role type for that argument.
 * @platform Desktop
 * @feature.area Multiple
 * @impact Insecure Coding Practice
 * @repro.text
 * @owner.email: sdat@microsoft.com
 * @opaqueid CQLD-C28147e
 * @problem.severity warning
 * @precision medium
 * @tags correctness
 * @scope domainspecific
 * @query-version v1
 */

import cpp
import drivers.libraries.RoleTypes
import semmle.code.cpp.TypedefType

from FunctionDeclarationEntry irtf
where
  irtf.getName().matches("EvtBthHfpDeviceNotificationStatusWorkItem") 
  
select irtf,
"$@ $@ $@ " , irtf.getTypedefType(), irtf.getTypedefType().toString()