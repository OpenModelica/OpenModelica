// name: FuncBuiltinDiagonal
// keywords: diagonal
// status: correct
// cflags: -d=newInst
//
// Tests the builtin diagonal operator.
//

model FuncBuiltinDiagonal
  Real x[3,3] = diagonal({1, 2, 3});
end FuncBuiltinDiagonal;

// Result:
// Error processing file: FuncBuiltinDiagonal.mo
// Error: Base class polymorphic not found in scope <unknown>.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
