// name: FuncBuiltinSymmetric
// keywords: symmetric
// status: correct
// cflags: -d=newInst
//
// Tests the builtin symmetric operator.
//

model FuncBuiltinSymmetric
  Real x[3,3] = symmetric({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
end FuncBuiltinSymmetric;

// Result:
// Error processing file: FuncBuiltinSymmetric.mo
// [flattening/modelica/scodeinst/FuncBuiltinSymmetric.mo:10:3-10:61:writable] Error: No matching function found for symmetric({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}) in component <REMOVE ME>
// candidates are :
//   symmetric()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
