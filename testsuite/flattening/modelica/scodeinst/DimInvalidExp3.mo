// name: DimInvalidExp3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model DimInvalidExp3
  Real x[size(y, 1)];
  Real y[:];
end DimInvalidExp3;

// Result:
// Error processing file: DimInvalidExp3.mo
// [flattening/modelica/scodeinst/DimInvalidExp3.mo:9:3-9:12:writable] Error: Failed to deduce dimension 1 of y due to missing binding equation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
