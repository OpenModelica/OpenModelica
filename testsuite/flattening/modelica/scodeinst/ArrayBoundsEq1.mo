// name: ArrayBoundsEq1
// keywords:
// status: incorrect
//

model ArrayBoundsEq1
  Real x[2] = ones(2);
  Real y;
equation
  y = x[3];
end ArrayBoundsEq1;

// Result:
// Error processing file: ArrayBoundsEq1.mo
// [flattening/modelica/scodeinst/ArrayBoundsEq1.mo:10:3-10:11:writable] Error: Subscript '3' for dimension 1 (size = 2) of x is out of bounds.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
