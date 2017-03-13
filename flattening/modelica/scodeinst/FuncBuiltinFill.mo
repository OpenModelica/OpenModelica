// name: FuncBuiltinFill
// keywords: fill
// status: correct
// cflags: -d=newInst
//
// Tests the builtin fill operator.
//

model FuncBuiltinFill
  Real x[4] = fill(1, 4);
  Real y[2, 4, 1] = fill(3.14, 2, 4, 1);
end FuncBuiltinFill;

// Result:
// Error processing file: FuncBuiltinFill.mo
// [flattening/modelica/scodeinst/FuncBuiltinFill.mo:11:3-11:40:writable] Error: No matching function found for fill(3.14, 2, 4, 1) in component <REMOVE ME>
// candidates are :
//   fill(s, n)
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
