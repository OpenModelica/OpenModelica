// name: DimInvalidExp1
// keywords:
// status: incorrect
//

model DimInvalidExp1
  parameter Integer n;
  Real x[n];
end DimInvalidExp1;

// Result:
// Error processing file: DimInvalidExp1.mo
// [flattening/modelica/scodeinst/DimInvalidExp1.mo:8:3-8:12:writable] Error: Could not evaluate structural parameter (or constant): n which gives dimensions of array: x. Array dimensions must be known at compile time.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
