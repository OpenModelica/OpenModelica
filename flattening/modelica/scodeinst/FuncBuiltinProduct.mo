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
// class FuncBuiltinProduct
//   Real r1 = /*Real*/(product({1, 2, 3}));
//   Real r2 = /*Real*/(product({{1}, {2}, {3}}));
//   Real r3 = /*Real*/(product({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}));
//   Real r4 = /*Real*/(product(1:0));
// end FuncBuiltinProduct;
// endResult
