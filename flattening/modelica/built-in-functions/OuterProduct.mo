// name: OuterProduct
// keywords: outerProduct
// status: correct
//
// Testing the built-in outerProduct function.
//

model OuterProduct
  Real v1[2] = {2, 1};
  Real v2[2] = {3, 2};
  Real r1[2, 2];
  Real r2[2, 2];
equation
  r1 = outerProduct({2, 1}, {3, 2});
  r2 = outerProduct(v1, v2);
end OuterProduct;

// Result:
// class OuterProduct
//   Real v1[1];
//   Real v1[2];
//   Real v2[1];
//   Real v2[2];
//   Real r1[1,1];
//   Real r1[1,2];
//   Real r1[2,1];
//   Real r1[2,2];
//   Real r2[1,1];
//   Real r2[1,2];
//   Real r2[2,1];
//   Real r2[2,2];
// equation
//   v1 = {2.0, 1.0};
//   v2 = {3.0, 2.0};
//   r1[1,1] = 6.0;
//   r1[1,2] = 4.0;
//   r1[2,1] = 3.0;
//   r1[2,2] = 2.0;
//   r2[1,1] = v1[1] * v2[1];
//   r2[1,2] = v1[1] * v2[2];
//   r2[2,1] = v1[2] * v2[1];
//   r2[2,2] = v1[2] * v2[2];
// end OuterProduct;
// endResult
