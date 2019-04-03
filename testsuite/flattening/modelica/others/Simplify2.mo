// name:     Simplify2
// keywords: simplify
// status:   correct
//
// Checks that expressions are not lost in simplify.
//

function foo
   input Real x[3];
   output Real y[3];
   annotation(derivative(noDerivative=x)= dfoo);
algorithm
   y := x;
end foo;

function dfoo
   input Real x[3];
   output Real y[3];
algorithm
   y := x;
end dfoo;


model Test
   Real x(start=0);
   parameter Real x_end=5;
   Real m[3];
equation
   m[1] = x+1.0;
   m[3] = x+2.0;
   4 = der(foo(m)*{0,1,0}+x);
   der(x) + x = x_end;
end Test;

// Result:
// function dfoo
//   input Real[3] x;
//   output Real[3] y;
// algorithm
//   y := {x[1], x[2], x[3]};
// end dfoo;
//
// function foo
//   input Real[3] x;
//   output Real[3] y;
// algorithm
//   y := {x[1], x[2], x[3]};
// end foo;
//
// class Test
//   Real x(start = 0.0);
//   parameter Real x_end = 5.0;
//   Real m[1];
//   Real m[2];
//   Real m[3];
// equation
//   m[1] = 1.0 + x;
//   m[3] = 2.0 + x;
//   4.0 = der(foo({m[1], m[2], m[3]}) * {0.0, 1.0, 0.0} + x);
//   der(x) + x = x_end;
// end Test;
// endResult
