// name:     IndexOutOfBoundsConnect3
// keywords: array subscript connect
// status:   incorrect
//
// Tests that indices out of bounds are caught in connect statements.
//

model IndexOutOfBoundsConnect3
  connector C
    Real e;
    flow Real f;
  end C;

  C c1[2], c2[2];
equation
  connect(c1[3], c2[1]);
end IndexOutOfBoundsConnect3;

// Result:
// Error processing file: IndexOutOfBoundsConnect3.mo
// [flattening/modelica/arrays/IndexOutOfBoundsConnect3.mo:16:3-16:24:writable] Error: Subscript '3' for dimension 1 (size = 2) of c1[3] is out of bounds.
// Error: Error occurred while flattening model IndexOutOfBoundsConnect3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
