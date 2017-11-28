// name: FuncBuiltinTranspose
// keywords: transpose
// status: correct
// cflags: -d=newInst
//
// Tests the builtin transpose operator.
//

model FuncBuiltinTranspose
  Real x[3, 3] = transpose({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
  Real y[2, 3] = transpose({{1, 2}, {4, 5}, {7, 8}});
  Real z[2, 3, 2] = transpose({{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}, {{9, 10}, {11, 12}}});
end FuncBuiltinTranspose;

// Result:
// class FuncBuiltinTranspose
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[1,3];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[2,3];
//   Real z[1,1,1];
//   Real z[1,1,2];
//   Real z[1,2,1];
//   Real z[1,2,2];
//   Real z[1,3,1];
//   Real z[1,3,2];
//   Real z[2,1,1];
//   Real z[2,1,2];
//   Real z[2,2,1];
//   Real z[2,2,2];
//   Real z[2,3,1];
//   Real z[2,3,2];
// equation
//   x = /*Real[3, 3]*/(transpose({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}));
//   y = /*Real[2, 3]*/(transpose({{1, 2}, {4, 5}, {7, 8}}));
//   z = /*Real[2, 3, 2]*/(transpose({{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}, {{9, 10}, {11, 12}}}));
// end FuncBuiltinTranspose;
// endResult
