// name: FuncBuiltinOuterProduct
// keywords: outerProduct
// status: correct
// cflags: -d=newInst
//
// Tests the builtin outerProduct operator.
//

model FuncBuiltinOuterProduct
  Real x[3,3] = outerProduct({1, 2, 3}, {4, 5, 6});
end FuncBuiltinOuterProduct;

// Result:
// Error processing file: FuncBuiltinOuterProduct.mo
// [lib/omc/ModelicaBuiltin.mo:335:3-335:39:writable] Error: No matching function found for size(v1, 1) in component <REMOVE ME>
// candidates are :
//   size()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
