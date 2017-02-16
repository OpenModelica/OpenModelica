// name: dim3.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//


model A
  parameter Integer n;
  Real x[n] = {1, 2, 3};
end A;

// Result:
// Error processing file: dim3.mo
// [flattening/modelica/scodeinst/dim3.mo:10:3-10:24:writable] Error: Could not evaluate structural parameter (or constant): n which gives dimensions of array: x. Array dimensions must be known at compile time.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
