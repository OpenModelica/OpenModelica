// name: Product
// keywords: product
// status: correct
//
// Testing the built-in product function.
//

model Product
  Real x1[3];
  Real x2[2, 2];
  Real x3[2, 2, 2];
  Real y1, y2, y3, y4, y5, y6;
equation
  y1 = product(x1);
  y2 = product(x2);
  y3 = product(x3);
  y4 = product({1, 2, 3});
  y5 = product({{3, 4}, {5, 6}});
  y6 = product({{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}});
end Product;

// Result:
// class Product
//   Real x1[1];
//   Real x1[2];
//   Real x1[3];
//   Real x2[1,1];
//   Real x2[1,2];
//   Real x2[2,1];
//   Real x2[2,2];
//   Real x3[1,1,1];
//   Real x3[1,1,2];
//   Real x3[1,2,1];
//   Real x3[1,2,2];
//   Real x3[2,1,1];
//   Real x3[2,1,2];
//   Real x3[2,2,1];
//   Real x3[2,2,2];
//   Real y1;
//   Real y2;
//   Real y3;
//   Real y4;
//   Real y5;
//   Real y6;
// equation
//   y1 = x1[1] * x1[2] * x1[3];
//   y2 = x2[1,1] * x2[1,2] * x2[2,1] * x2[2,2];
//   y3 = x3[1,2,1] * x3[1,2,2] * x3[1,1,1] * x3[1,1,2] * x3[2,2,1] * x3[2,2,2] * x3[2,1,1] * x3[2,1,2];
//   y4 = 6.0;
//   y5 = 360.0;
//   y6 = 40320.0;
// end Product;
// endResult
