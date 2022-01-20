// name: FuncBuiltinSum2
// keywords: sum
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin sum operator.
//

model FuncBuiltinSum2
  Real x = sum(0);
end FuncBuiltinSum2;

// Result:
// Error processing file: FuncBuiltinSum2.mo
// [flattening/modelica/scodeinst/FuncBuiltinSum2.mo:10:3-10:18:writable] Error: Type mismatch for positional argument 1 in sum(a=0). The argument has type:
//   Integer
// expected type:
//   Array
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
