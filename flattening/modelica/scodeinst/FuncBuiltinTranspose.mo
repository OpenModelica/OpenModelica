// name: FuncBuiltinTranspose
// keywords: transpose
// status: correct
// cflags: -d=newInst
//
// Tests the builtin transpose operator.
//

model FuncBuiltinTranspose
  Real x[3, 3] = transpose({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
  Real y[2, 3] = transpose({{1, 2}, {4, 5}, {7, 8}});
  Real z[2, 3, 2] = transpose({{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}, {{9, 10}, {11, 12}}});
end FuncBuiltinTranspose;

// Result:
// Error processing file: FuncBuiltinTranspose.mo
// [flattening/modelica/scodeinst/FuncBuiltinTranspose.mo:10:3-10:62:writable] Error: No matching function found for transpose({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}) in component <REMOVE ME>
// candidates are :
//   transpose()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
