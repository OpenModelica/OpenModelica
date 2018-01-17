// name: FuncBuiltinZeros
// keywords: zeros
// status: correct
// cflags: -d=newInst
//
// Tests the builtin zeros operator.
//

model FuncBuiltinZeros
  Real x[3] = zeros(3);
  Real y[4, 2] = zeros(4, 2);
end FuncBuiltinZeros;

// Result:
// class FuncBuiltinZeros
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1,1];
//   Real y[1,2];
//   Real y[2,1];
//   Real y[2,2];
//   Real y[3,1];
//   Real y[3,2];
//   Real y[4,1];
//   Real y[4,2];
// equation
//   x = {0.0, 0.0, 0.0};
//   y = {{0.0, 0.0}, {0.0, 0.0}, {0.0, 0.0}, {0.0, 0.0}};
// end FuncBuiltinZeros;
// endResult
