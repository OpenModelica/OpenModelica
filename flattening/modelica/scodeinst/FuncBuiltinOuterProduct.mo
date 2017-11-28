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
// Error: Cannot resolve type of expression ' matrix(v1) .* transpose(matrix(v2)) '. The operands have types ' Real[:, 1] .* Real[1, :] ' in component Real[:, 1].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
