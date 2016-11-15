// name: extends1.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
// FAILREASON: Duplicate elements from extends not checked.
//


model A
  Real x;
end A;

model B
  Integer x;
end B;

model C
  extends A;
  extends B;
end C;

// Result:
//
// EXPANDED FORM:
//
// class C
//   Integer x;
// end C;
//
//
// Found 1 components and 0 parameters.
// Error processing file: extends1.mo
// [extends1.mo:12:3-12:12:writable] Error: Duplicate elements (due to inherited elements) not identical:
//   first element is:  .Integer x
//   second element is: .Real x
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
