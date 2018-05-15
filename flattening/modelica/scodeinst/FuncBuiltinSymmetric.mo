// name: FuncBuiltinSymmetric
// keywords: symmetric
// status: correct
// cflags: -d=newInst
//
// Tests the builtin symmetric operator.
//

model FuncBuiltinSymmetric
  Real x[4, 4] = symmetric({{11, 12, 13, 14},
                            {21, 22, 23, 24},
                            {31, 32, 33, 34},
                            {41, 42, 43, 44}});
end FuncBuiltinSymmetric;

// Result:
// class FuncBuiltinSymmetric
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[1,4];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[2,4];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
//   Real x[3,4];
//   Real x[4,1];
//   Real x[4,2];
//   Real x[4,3];
//   Real x[4,4];
// equation
//   x = {{11.0, 12.0, 13.0, 14.0}, {12.0, 22.0, 23.0, 24.0}, {13.0, 23.0, 33.0, 34.0}, {14.0, 24.0, 34.0, 44.0}};
// end FuncBuiltinSymmetric;
// endResult
