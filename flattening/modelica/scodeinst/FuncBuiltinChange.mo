// name: FuncBuiltinChange
// keywords: change
// status: correct
// cflags: -d=newInst
//
// Tests the builtin change operator.
//

model FuncBuiltinChange
  discrete Real x;
  Boolean y = change(x);
end FuncBuiltinChange;

// Result:
// Error processing file: FuncBuiltinChange.mo
// [flattening/modelica/scodeinst/FuncBuiltinChange.mo:11:3-11:24:writable] Error: No matching function found for change(x) in component <REMOVE ME>
// candidates are :
//   change()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
