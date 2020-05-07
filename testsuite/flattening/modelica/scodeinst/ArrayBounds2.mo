// name: ArrayBounds2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  Real x[3];
end A;

model ArrayBounds2
  A a[2];
  Real y = a[3].x[1];
end ArrayBounds2;

// Result:
// Error processing file: ArrayBounds2.mo
// [flattening/modelica/scodeinst/ArrayBounds2.mo:13:3-13:21:writable] Error: Subscript '3' for dimension 1 (size = 2) of a is out of bounds.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
