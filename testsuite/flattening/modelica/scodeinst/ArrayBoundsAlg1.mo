// name: ArrayBoundsAlg1
// keywords:
// status: incorrect
//

model ArrayBoundsAlg1
  Real x[2] = ones(2);
  Real y;
algorithm
  y := x[3];
end ArrayBoundsAlg1;

// Result:
// Error processing file: ArrayBoundsAlg1.mo
// [flattening/modelica/scodeinst/ArrayBoundsAlg1.mo:10:3-10:12:writable] Error: Subscript '3' for dimension 1 (size = 2) of x is out of bounds.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
