// name:     IndexOutOfBoundsConnect2
// keywords: array subscript connect
// status:   incorrect
//
// Tests that indices out of bounds are caught in connect statements.
//

model IndexOutOfBoundsConnect2
  connector C
    Real e;
    flow Real f;
  end C;

  C c1[2], c2[2];
equation
  connect(c1[1], c2[0]);
end IndexOutOfBoundsConnect2;

// Result:
// Error processing file: IndexOutOfBoundsConnect2.mo
// [flattening/modelica/arrays/IndexOutOfBoundsConnect2.mo:16:3-16:24:writable] Error: Subscript '0' for dimension 1 (size = 2) of c2[0] is out of bounds.
// Error: Error occurred while flattening model IndexOutOfBoundsConnect2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
