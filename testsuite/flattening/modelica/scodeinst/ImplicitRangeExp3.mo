// name: ImplicitRangeExp3
// keywords:
// status: correct
//
//

function f
  input Real x[:];
  input Real y[size(x, 1)];
  output Real z;
algorithm
  z := x * y;
end f;

model ImplicitRangeExp3
  Real x[3], y[3];
  Real z = f(x, y);
end ImplicitRangeExp3;

// Result:
// function f
//   input Real[:] x;
//   input Real[size(x, 1)] y;
//   output Real z;
// algorithm
//   z := x * y;
// end f;
//
// class ImplicitRangeExp3
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real z = f(x, y);
// end ImplicitRangeExp3;
// endResult
