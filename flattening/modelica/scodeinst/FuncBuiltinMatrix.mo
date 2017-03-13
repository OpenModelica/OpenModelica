// name: FuncBuiltinMatrix
// keywords: matrix
// status: correct
// cflags: -d=newInst
//
// Tests the builtin matrix operator.
//

model FuncBuiltinMatrix
  Real x[1,1] = matrix(1);
  Real y[3,1] = matrix({{1}, {2}, {3}});
  Real z[3,1] = matrix({1, 2, 3});
end FuncBuiltinMatrix;

// Result:
// Error processing file: FuncBuiltinMatrix.mo
// [flattening/modelica/scodeinst/FuncBuiltinMatrix.mo:10:3-10:26:writable] Error: No matching function found for matrix(1) in component <REMOVE ME>
// candidates are :
//   matrix()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
