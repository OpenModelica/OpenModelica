// name: FuncBuiltinSmooth
// keywords: smooth
// status: correct
// cflags: -d=newInst
//
// Tests the builtin smooth operator.
//

model FuncBuiltinSmooth
  Real x = time;
  Real y = smooth(1, x);
  Real z = smooth(2, {x, x});
end FuncBuiltinSmooth;

// Result:
// Error processing file: FuncBuiltinSmooth.mo
// [flattening/modelica/scodeinst/FuncBuiltinSmooth.mo:11:3-11:24:writable] Error: No matching function found for smooth(2, x) in component <REMOVE ME>
// candidates are :
//   smooth()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
