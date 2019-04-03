// name: ReductionInvalidTypeProduct
// keywords: reduction
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin reduction operators.
//

model ReductionInvalidTypeProduct
  Real x = product({1, 2, 3} for i in 1:3);
end ReductionInvalidTypeProduct;

// Result:
// Error processing file: ReductionInvalidTypeProduct.mo
// [flattening/modelica/scodeinst/ReductionInvalidTypeProduct.mo:10:3-10:43:writable] Error: Invalid expression ‘{1, 2, 3}‘ of type Integer[3] in product reduction, expected scalar Integer or Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
