// name: FuncBuiltinNdims
// keywords: ndims
// status: correct
// cflags: -d=newInst
//
// Tests the builtin ndims operator.
//

model FuncBuiltinNdims
  Real x[1, 2, 3];
  Integer i = ndims(x);
  Integer j = ndims({{1},{2}});
  Integer k = ndims(2);
end FuncBuiltinNdims;

// Result:
// Error processing file: FuncBuiltinNdims.mo
// [flattening/modelica/scodeinst/FuncBuiltinNdims.mo:11:3-11:23:writable] Error: No matching function found for ndims(x) in component <REMOVE ME>
// candidates are :
//   ndims()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
