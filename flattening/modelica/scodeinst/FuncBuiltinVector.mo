// name: FuncBuiltinVector
// keywords: vector
// status: correct
// cflags: -d=newInst
//
// Tests the builtin vector operator.
//

model FuncBuiltinVector
  Real x[1] = vector(1);
  Real y[3] = vector({{1}, {2}, {3}});
  Real z[3] = vector({1, 2, 3});
end FuncBuiltinVector;

// Result:
// class FuncBuiltinVector
//   Real x[1];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real z[1];
//   Real z[2];
//   Real z[3];
// equation
//   x = /*Real[1]*/(vector(1));
//   y = /*Real[3]*/(vector({{1}, {2}, {3}}));
//   z = /*Real[3]*/(vector({1, 2, 3}));
// end FuncBuiltinVector;
// endResult
