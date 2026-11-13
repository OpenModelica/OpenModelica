// name: FuncBuiltinMatrixWrongType2
// keywords: matrix
// status: incorrect
//
// Tests the builtin matrix operator.
//

model FuncBuiltinMatrixWrongType2
  Real x[2,2,0];
  Real y[2,2] = matrix(x);
end FuncBuiltinMatrixWrongType2;

// Result:
// Error processing file: FuncBuiltinMatrixWrongType2.mo
// [flattening/modelica/scodeinst/FuncBuiltinMatrixWrongType2.mo:10:3-10:26:writable] Error: Invalid dimension 3 of argument to matrix, expected dimension size 1 but got 0.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
