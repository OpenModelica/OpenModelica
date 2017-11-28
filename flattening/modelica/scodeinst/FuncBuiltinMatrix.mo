// name: FuncBuiltinMatrix
// keywords: matrix
// status: correct
// cflags: -d=newInst
//
// Tests the builtin matrix operator.
//

model FuncBuiltinMatrix
  Real x[1,1] = matrix(1);
  Real y[3,1] = matrix({{1}, {2}, {3}});
  Real z[3,1] = matrix({1, 2, 3});
  Real a[3,3] = matrix({{{1}, {2}, {3}}, {{1}, {2}, {3}}, {{1}, {2}, {3}}}); // 3x3x1
end FuncBuiltinMatrix;

// Result:
// class FuncBuiltinMatrix
//   Real x[1,1];
//   Real y[1,1];
//   Real y[2,1];
//   Real y[3,1];
//   Real z[1,1];
//   Real z[2,1];
//   Real z[3,1];
//   Real a[1,1];
//   Real a[1,2];
//   Real a[1,3];
//   Real a[2,1];
//   Real a[2,2];
//   Real a[2,3];
//   Real a[3,1];
//   Real a[3,2];
//   Real a[3,3];
// equation
//   x = /*Real[1, 1]*/(matrix(1));
//   y = /*Real[3, 1]*/(matrix({{1}, {2}, {3}}));
//   z = /*Real[3, 1]*/(matrix({1, 2, 3}));
//   a = /*Real[3, 3]*/(matrix({{{1}, {2}, {3}}, {{1}, {2}, {3}}, {{1}, {2}, {3}}}));
// end FuncBuiltinMatrix;
// endResult
