// name: FuncBuiltinSum
// keywords: sum
// status: correct
// cflags: -d=newInst
//
// Tests the builtin sum operator.
//

model FuncBuiltinMax
  Real r1 = sum({1, 2, 3});
  Real r2 = sum({{1}, {2}, {3}});
  Real r3 = sum({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
  Real r4 = sum(1:0);
end FuncBuiltinMax;

// Result:
// Error processing file: FuncBuiltinSum.mo
// [flattening/modelica/scodeinst/FuncBuiltinSum.mo:10:3-10:27:writable] Error: No matching function found for sum({1, 2, 3}) in component <REMOVE ME>
// candidates are :
//   sum()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
