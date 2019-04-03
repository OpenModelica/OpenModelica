// name: DimInvalidExp2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model DimInvalidExp2
  parameter Integer n;
  Real x[n] = {1, 2, 3};
end DimInvalidExp2;

// Result:
// Error processing file: DimInvalidExp2.mo
// [flattening/modelica/scodeinst/DimInvalidExp2.mo:9:3-9:24:writable] Error: Could not evaluate structural parameter (or constant): n which gives dimensions of array: x. Array dimensions must be known at compile time.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
