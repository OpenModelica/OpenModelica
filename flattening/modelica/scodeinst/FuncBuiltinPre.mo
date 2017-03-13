// name: FuncBuiltinPre
// keywords: pre
// status: correct
// cflags: -d=newInst
//
// Tests the builtin pre operator.
//

model FuncBuiltinPre
  discrete Real x;
  Real y = pre(x);
end FuncBuiltinPre;

// Result:
// Error processing file: FuncBuiltinPre.mo
// [flattening/modelica/scodeinst/FuncBuiltinPre.mo:11:3-11:18:writable] Error: No matching function found for pre(x) in component <REMOVE ME>
// candidates are :
//   pre()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
