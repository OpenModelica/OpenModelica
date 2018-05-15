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
// class FuncBuiltinOuterProduct
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
// equation
//   x = {{4.0, 5.0, 6.0}, {8.0, 10.0, 12.0}, {12.0, 15.0, 18.0}};
// end FuncBuiltinOuterProduct;
// endResult
