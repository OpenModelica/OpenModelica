// name: FuncDefaultArg3
// keywords:
// status: correct
//
//

function f
  input Real x[:];
  input Real y = x[1];
  output Real z[size(x, 1)] = y * x;
end f;

model FuncDefaultArg3
  Real x[:] = f({2, 3, 4});
end FuncDefaultArg3;

// Result:
// class FuncDefaultArg3
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {4.0, 6.0, 8.0};
// end FuncDefaultArg3;
// endResult
