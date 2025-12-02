// name: ArrayBounds1
// keywords:
// status: incorrect
//

model ArrayBounds1
  Real x[3];
  Real y = x[4];
end ArrayBounds1;

// Result:
// Error processing file: ArrayBounds1.mo
// [flattening/modelica/scodeinst/ArrayBounds1.mo:8:3-8:16:writable] Error: Subscript '4' for dimension 1 (size = 3) of x is out of bounds.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
