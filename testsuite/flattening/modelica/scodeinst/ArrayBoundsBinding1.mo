// name: ArrayBoundsBinding1
// keywords:
// status: incorrect
//

model ArrayBoundsBinding1
  Real x[1, 3];
  Real y = x[1, 4];
end ArrayBoundsBinding1;

// Result:
// Error processing file: ArrayBoundsBinding1.mo
// [flattening/modelica/scodeinst/ArrayBoundsBinding1.mo:8:3-8:19:writable] Error: Subscript '4' for dimension 2 (size = 3) of x is out of bounds.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
