// name:     Function1
// keywords: function
// status:   correct
// cflags: -d=-newInst
//
// This tests basic function functionality

function f
  input Real x;
  output Real r;
algorithm
  r := 2.0 * x;
end f;

model Function1
  Real x, y, z;
equation
  x = f(z);
  y = f(z);
end Function1;

// Result:
// function f
//   input Real x;
//   output Real r;
// algorithm
//   r := 2.0 * x;
// end f;
//
// class Function1
//   Real x;
//   Real y;
//   Real z;
// equation
//   x = f(z);
//   y = f(z);
// end Function1;
// endResult
