// name: FunctionInverse1
// keywords: inverse
// status: correct
//

function f
  input Real x;
  input Real y;
  output Real z;
algorithm
  z := x*y + 1e-10*sin(x*y);
  annotation(inverse(y = f_inv(x, z)));
end f;

function f_inv
  input Real x;
  input Real z;
  output Real y;
algorithm
  y := z / x;
end f_inv;

model FunctionInverse1
  Real x, y, z;
equation
  x = 10 + sin(time);
  z = 2*x;
  f(x, y) = z;
end FunctionInverse1;

// Result:
// function f
//   input Real x;
//   input Real y;
//   output Real z;
// algorithm
//   z := x * y + 1e-10 * sin(x * y);
// end f;
//
// function f_inv
//   input Real x;
//   input Real z;
//   output Real y;
// algorithm
//   y := z / x;
// end f_inv;
//
// class FunctionInverse1
//   Real x;
//   Real y;
//   Real z;
// equation
//   x = 10.0 + sin(time);
//   z = 2.0 * x;
//   f(x, y) = z;
// end FunctionInverse1;
// endResult
