// name: FuncBuiltinOnes
// keywords: ones
// status: correct
// cflags: -d=newInst
//
// Tests the builtin ones operator.
//

model FuncBuiltinOnes
  Real x[3] = ones(3);
  Real y[4, 2] = ones(4, 2);
end FuncBuiltinOnes;

// Result:
// class FuncBuiltinOnes
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
//   x = {1.0, 1.0, 1.0};
//   y = {{1.0, 1.0}, {1.0, 1.0}, {1.0, 1.0}, {1.0, 1.0}};
// end FuncBuiltinOnes;
// endResult
