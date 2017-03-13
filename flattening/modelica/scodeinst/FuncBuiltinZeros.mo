// name: FuncBuiltinZeros
// keywords: zeros
// status: correct
// cflags: -d=newInst
//
// Tests the builtin zeros operator.
//

model FuncBuiltinZeros
  Real x[3] = zeros(3);
  Real y[4, 2] = zeros(4, 2);
end FuncBuiltinZeros;

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
