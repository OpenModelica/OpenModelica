// name: FuncBuiltinSymmetric2
// keywords: symmetric
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin symmetric operator.
//

model FuncBuiltinSymmetric2
  Real x[:, :] = symmetric({{11, 12, 13},
                            {21, 22, 23},
                            {31, 32, 33},
                            {41, 42, 43}});
end FuncBuiltinSymmetric2;

// Result:
// Error processing file: FuncBuiltinSymmetric2.mo
// [flattening/modelica/scodeinst/FuncBuiltinSymmetric2.mo:10:3-13:43:writable] Error: Type mismatch for positional argument 1 in symmetric(={{11, 12, 13}, {21, 22, 23}, {31, 32, 33}, {41, 42, 43}}). The argument has type:
//   Integer[4, 3]
// expected type:
//   Any[n, n]
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
