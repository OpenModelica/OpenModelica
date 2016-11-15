// name: func2.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//


model A
  function f
  end f;

  Real x = f();
  Real y = min(2, 3);
end A;

model B
  A a;
  Real x = A.f();
end B;

// Result:
//
// EXPANDED FORM:
//
// class B
//   Real a.x = a.f();
//   Real a.y = 2;
//   Real x = A.f();
// end B;
//
//
// Found 3 components and 0 parameters.
// Error processing file: func2.mo
// [func2.mo:16:3-16:6:writable] Error: Variable a: Internal error ValuesUtil.valueExp failed for
// [func2.mo:11:3-11:15:writable] Error: Type mismatch in binding x = A.f(), expected subtype of Real, got type #NORETCALL#.
// Error: Error occurred while flattening model B
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
