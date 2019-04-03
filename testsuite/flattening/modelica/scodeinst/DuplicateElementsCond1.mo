// name: DuplicateElementsCond1.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//


model A
  Real x if true;
end A;

model B
  Real x;
end B;

model C
  extends A;
  extends B;
  Real x if true;
end C;

// Result:
//
// EXPANDED FORM:
//
// class C
//   Real x;
// end C;
//
//
// Found 1 components and 0 parameters.
// Error processing file: extends2.mo
// [extends2.mo:18:3-18:17:writable] Error: Duplicate elements (due to inherited elements) not identical:
//   first element is:  Real x if true
//   second element is: .Real x
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
