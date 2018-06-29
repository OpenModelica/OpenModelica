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
  Real x[3];
  Real r5 = product(x);
end FuncBuiltinProduct;

// Result:
// class FuncBuiltinProduct
//   Real r1 = 6.0;
//   Real r2 = 6.0;
//   Real r3 = 362880.0;
//   Real r4 = 1.0;
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real r5 = x[1] * x[2] * x[3];
// end FuncBuiltinProduct;
// endResult
