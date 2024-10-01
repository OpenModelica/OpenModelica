// name: FunctionInverse2
// keywords: inverse
// status: correct
//

function f
  input Real x;
  input Real y;
  output Real z;
algorithm
  z := x*y + 1e-10*sin(x*y);
  annotation(inverse(y = f_inv_x(x, z), x = f_inv_y(y, z)));
end f;

function f_inv_x
  input Real x;
  input Real z;
  output Real y;
algorithm
  y := z / x;
end f_inv_x;

function f_inv_y
  input Real y;
  input Real z;
  output Real x;
algorithm
  x := z / y;
end f_inv_y;

model FunctionInverse2
  Real x, y, z;
equation
  x = 10 + sin(time);
  z = 2*x;
  f(x, y) = z;
end FunctionInverse2;

// Result:
// function f
//   input Real x;
//   input Real y;
//   output Real z;
// algorithm
//   z := x * y + 1e-10 * sin(x * y);
// end f;
//
// function f_inv_x
//   input Real x;
//   input Real z;
//   output Real y;
// algorithm
//   y := z / x;
// end f_inv_x;
//
// function f_inv_y
//   input Real y;
//   input Real z;
//   output Real x;
// algorithm
//   x := z / y;
// end f_inv_y;
//
// class FunctionInverse2
//   Real x;
//   Real y;
//   Real z;
// equation
//   x = 10.0 + sin(time);
//   z = 2.0 * x;
//   f(x, y) = z;
// end FunctionInverse2;
// endResult
