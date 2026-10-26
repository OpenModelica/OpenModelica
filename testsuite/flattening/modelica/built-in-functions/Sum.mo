// name: Sum
// keywords: sum
// status: correct
//
// Testing the built-in sum function.
//

model Sum
  parameter Real x[3](each fixed = false);
  Real y[3];
  Real z[2,2,2] = fill(1,2,2,2);
  Real a,b,c;
equation
  a = sum(x);
  b = sum(y);
  c = sum(z);
end Sum;

// Result:
// class Sum
//   parameter Real x[1](fixed = false);
//   parameter Real x[2](fixed = false);
//   parameter Real x[3](fixed = false);
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real z[1,1,1];
//   Real z[1,1,2];
//   Real z[1,2,1];
//   Real z[1,2,2];
//   Real z[2,1,1];
//   Real z[2,1,2];
//   Real z[2,2,1];
//   Real z[2,2,2];
//   Real a;
//   Real b;
//   Real c;
// equation
//   z = {{{1.0, 1.0}, {1.0, 1.0}}, {{1.0, 1.0}, {1.0, 1.0}}};
//   a = x[1] + x[2] + x[3];
//   b = y[1] + y[2] + y[3];
//   c = z[1,1,1] + z[1,1,2] + z[1,2,1] + z[1,2,2] + z[2,1,1] + z[2,1,2] + z[2,2,1] + z[2,2,2];
// end Sum;
// endResult
