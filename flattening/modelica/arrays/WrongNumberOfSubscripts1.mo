// name:     WrongNumberOfSubscripts1
// keywords: array subscript
// status:   incorrect
//
// Tests that using too many subscripts gives an error.
//

model WrongNumberOfSubscripts1
  Real x[2, 3] = {{1, 2, 3}, {4, 5, 6}};
  Real y = x[1, 2, 3];
end WrongNumberOfSubscripts1;

// Result:
// Error processing file: WrongNumberOfSubscripts1.mo
// [flattening/modelica/arrays/WrongNumberOfSubscripts1.mo:10:3-10:22:writable] Error: Wrong number of subscripts in x[1,2,3] (3 subscripts for 2 dimensions).
// [flattening/modelica/arrays/WrongNumberOfSubscripts1.mo:10:3-10:22:writable] Error: Variable x[1,2,3] not found in scope WrongNumberOfSubscripts1.
// Error: Error occurred while flattening model WrongNumberOfSubscripts1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
