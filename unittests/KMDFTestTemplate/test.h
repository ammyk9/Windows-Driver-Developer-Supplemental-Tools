#pragma once

//
// extern
extern "C"
{
  typedef VOID
  TYPEDEF_TEST1(
      _In_ int i);

  typedef TYPEDEF_TEST1 *ITEM1;
}

// global namespace
typedef VOID TYPEDEF_TEST2(
    _In_ int i);

typedef TYPEDEF_TEST2 *ITEM2;


// some other namespace
namespace SomeOtherNamespace
{
  typedef VOID TYPEDEF_TEST3(
      _In_ int i);

  typedef TYPEDEF_TEST3 *ITEM3;
}


class SomeClass
{

public:
  NTSTATUS Init();
  //=====================================================================
  // Default CUnknown
  static TYPEDEF_TEST1 typedefFunction; // This typedef is NOT found
  static TYPEDEF_TEST2 typedefFunction2; // This typedef is found
};

namespace SomeOtherNamespace
{
  class SomeClassSomeOtherNamespace
  {

  public:
    NTSTATUS Init();
    //=====================================================================
    // Default CUnknown
    static TYPEDEF_TEST1 typedefFunction3; // This typedef is NOT found
    static TYPEDEF_TEST2 typedefFunction4; // This typedef is found 
    static TYPEDEF_TEST3 typedefFunction5; // This typedef is found
  };
}

#pragma code_seg()
VOID SomeClass::typedefFunction(
    _In_ int i)
{
  i = NULL;
}

#pragma code_seg()
VOID SomeClass::typedefFunction2(
    _In_ int i)
{
  i = NULL;
}

namespace SomeOtherNamespace
{

#pragma code_seg()
  VOID SomeClassSomeOtherNamespace::typedefFunction3(
      _In_ int i)
  {
    i = NULL;
  }

#pragma code_seg()
  VOID SomeClassSomeOtherNamespace::typedefFunction4(
      _In_ int i)
  {
    i = NULL;
  }

#pragma code_seg()
  VOID SomeClassSomeOtherNamespace::typedefFunction5(
      _In_ int i)
  {
    i = NULL;
  }
} // namespace SomeOtherNamespace