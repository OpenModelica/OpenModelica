// name: DimSize4
// keywords:
// status: incorrect
//

model DimSize4
  Integer n = 1;
  Real x[3];
  Real y[size(x, n)];
end DimSize4;

// Result:
// Error processing file: DimSize4.mo
// [flattening/modelica/scodeinst/DimSize4.mo:9:3-9:21:writable] Error: Dimensions must be parameter or constant expression (in size(x, n)).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
