// name: FuncBuiltinSymmetric
// keywords: symmetric
// status: correct
// cflags: -d=newInst
//
// Tests the builtin symmetric operator.
//

model FuncBuiltinSymmetric
  Real x[3,3] = symmetric({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
end FuncBuiltinSymmetric;

// Result:
// class FuncBuiltinSymmetric
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
//   x = /*Real[3, 3]*/(symmetric({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}));
// end FuncBuiltinSymmetric;
// endResult
