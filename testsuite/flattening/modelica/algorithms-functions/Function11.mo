// name:     Function11
// keywords: function, default values
// status:   correct
//
// This tests default values for function arguments.


function equal
 input Real x[:];
 input Real y[:];
 input Real eps=1e-6;
 output Boolean equal;
algorithm
 equal := false;
end equal;

model test
  Real x[2],y[2]={1,2};
  Boolean b;
equation
x=y;
b = equal(x,y);
end test;

// Result:
// function equal
//   input Real[:] x;
//   input Real[:] y;
//   input Real eps = 1e-6;
//   output Boolean equal;
// algorithm
//   equal := false;
// end equal;
//
// class test
//   Real x[1];
//   Real x[2];
//   Real y[1];
//   Real y[2];
//   Boolean b;
// equation
//   y = {1.0, 2.0};
//   x[1] = y[1];
//   x[2] = y[2];
//   b = equal(x, y, 1e-6);
// end test;
// endResult
