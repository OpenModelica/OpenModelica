// name:     IndexOutOfBoundsConnect4
// keywords: array subscript connect
// status:   incorrect
//
// Tests that indices out of bounds are caught in connect statements.
//

model IndexOutOfBoundsConnect4
  connector C
    Real e;
    flow Real f;
  end C;

  C c1[2], c2[2];
equation
  connect(c1[2:3], c2[1:2]);
end IndexOutOfBoundsConnect4;

// Result:
// Error processing file: IndexOutOfBoundsConnect4.mo
// [flattening/modelica/arrays/IndexOutOfBoundsConnect4.mo:16:3-16:28:writable] Error: Subscript '3' for dimension 1 (size = 2) of c1[{2, 3}] is out of bounds.
// Error: Error occurred while flattening model IndexOutOfBoundsConnect4
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
