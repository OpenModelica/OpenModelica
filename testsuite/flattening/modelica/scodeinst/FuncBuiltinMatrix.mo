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
  Real b[3,3] = matrix(a);
  Real v[3] = {1, 2, 3};
  Real c[3,1] = matrix(v);
  Real s = 1;
  Real d[1,1] = matrix(s);
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
//   Real b[1,1];
//   Real b[1,2];
//   Real b[1,3];
//   Real b[2,1];
//   Real b[2,2];
//   Real b[2,3];
//   Real b[3,1];
//   Real b[3,2];
//   Real b[3,3];
//   Real v[1];
//   Real v[2];
//   Real v[3];
//   Real c[1,1];
//   Real c[2,1];
//   Real c[3,1];
//   Real s = 1.0;
//   Real d[1,1];
// equation
//   x = {{1.0}};
//   y = {{1.0}, {2.0}, {3.0}};
//   z = {{1.0}, {2.0}, {3.0}};
//   a = {{1.0, 2.0, 3.0}, {1.0, 2.0, 3.0}, {1.0, 2.0, 3.0}};
//   b = a;
//   v = {1.0, 2.0, 3.0};
//   c = {{v[1]}, {v[2]}, {v[3]}};
//   d = {{s}};
// end FuncBuiltinMatrix;
// endResult
