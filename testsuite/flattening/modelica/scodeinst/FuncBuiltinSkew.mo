// name: FuncBuiltinSkew
// keywords: skew
// status: correct
// cflags: -d=newInst
//
// Tests the builtin skew operator.
//

model FuncBuiltinSkew
  Real x[3, 3] = skew({1, 2, 3});
end FuncBuiltinSkew;

// Result:
// class FuncBuiltinSkew
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
//   x = {{0.0, -3.0, 2.0}, {3.0, 0.0, -1.0}, {-2.0, 1.0, 0.0}};
// end FuncBuiltinSkew;
// endResult
