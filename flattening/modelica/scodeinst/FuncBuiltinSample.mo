// name: FuncBuiltinSample
// keywords: sample
// status: correct
// cflags: -d=newInst
//
// Tests the builtin sample operator.
//

model FuncBuiltinSample
  Boolean b = sample(1.0, 2);
end FuncBuiltinSample;

// Result:
// Error processing file: FuncBuiltinSample.mo
// [flattening/modelica/scodeinst/FuncBuiltinSample.mo:10:3-10:29:writable] Error: No matching function found for sample(1, 2) in component <REMOVE ME>
// candidates are :
//   sample()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
