// name: FuncBuiltinOnes
// keywords: ones
// status: correct
// cflags: -d=newInst
//
// Tests the builtin ones operator.
//

model FuncBuiltinOnes
  Real x[3] = ones(3);
  Real y[4, 2] = ones(4, 2);
end FuncBuiltinOnes;

// Result:
// Error processing file: FuncBuiltinZeros.mo
// [flattening/modelica/scodeinst/FuncBuiltinZeros.mo:11:3-11:29:writable] Error: No matching function found for zeros(4, 2) in component <REMOVE ME>
// candidates are :
//   zeros(n)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
