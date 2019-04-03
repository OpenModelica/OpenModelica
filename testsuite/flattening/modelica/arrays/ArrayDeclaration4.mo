// name: ArrayDeclaration4
// keywords: array
// status: incorrect
//
// Tests declaring arrays with negative dimensions
// This test should fail
//

model ArrayDeclaration4
  Real errArr[-2];
end ArrayDeclaration4;

// Result:
// Error processing file: ArrayDeclaration4.mo
// [flattening/modelica/arrays/ArrayDeclaration4.mo:10:3-10:18:writable] Error: Negative dimension index (-2) for component errArr.
// Error: Error occurred while flattening model ArrayDeclaration4
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
