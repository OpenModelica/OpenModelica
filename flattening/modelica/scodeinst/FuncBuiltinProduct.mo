// name: FuncBuiltinProduct
// keywords: product
// status: correct
// cflags: -d=newInst
//
// Tests the builtin product operator.
//

model FuncBuiltinProduct
  Real r1 = product({1, 2, 3});
  Real r2 = product({{1}, {2}, {3}});
  Real r3 = product({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
  Real r4 = product(1:0);
end FuncBuiltinProduct;

// Result:
// Error processing file: FuncBuiltinProduct.mo
// [flattening/modelica/scodeinst/FuncBuiltinProduct.mo:10:3-10:31:writable] Error: No matching function found for product({1, 2, 3}) in component <REMOVE ME>
// candidates are :
//   product()
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
