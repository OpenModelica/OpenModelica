// name: FuncBuiltinMatrixWrongType1
// keywords: matrix
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin matrix operator.
//

model FuncBuiltinMatrixWrongType1
  Real x[3,3] = matrix({{{1, 2}, {2, 2}, {3, 2}}, {{1, 2}, {2, 2}, {3, 2}}, {{1, 2}, {2, 2}, {3, 2}}});
end FuncBuiltinMatrixWrongType1;

// Result:
// Error processing file: FuncBuiltinMatrixWrongType1.mo
// [flattening/modelica/scodeinst/FuncBuiltinMatrixWrongType1.mo:10:3-10:103:writable] Error: Invalid dimension 3 of argument to matrix, expected dimension size 1 but got 2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
