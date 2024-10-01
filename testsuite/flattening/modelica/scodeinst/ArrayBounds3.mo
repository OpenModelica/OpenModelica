// name: ArrayBounds3
// keywords:
// status: incorrect
//

model ArrayBounds3
  parameter Integer n = 2;
  Real x[n];
  Real y = x[n + 1];
end ArrayBounds3;

// Result:
// Error processing file: ArrayBounds3.mo
// [flattening/modelica/scodeinst/ArrayBounds3.mo:9:3-9:20:writable] Error: Subscript '3' for dimension 1 (size = 2) of x is out of bounds.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
