// name: FuncBuiltinSize
// keywords: size
// status: correct
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model FuncBuiltinSize
  Real x[1, 2, 3];
  Integer i1 = size(x, 1);
  Integer i2 = size(x, 2);
  Integer i3 = size(x, 3);
  Integer i4 = size({1, 2, 3}, 1);
  Integer i5[3] = size(x);
end FuncBuiltinSize;

// Result:
// Error processing file: FuncBuiltinSize.mo
// [flattening/modelica/scodeinst/FuncBuiltinSize.mo:11:3-11:26:writable] Error: No matching function found for size(x, 1) in component <REMOVE ME>
// candidates are :
//   size()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
