// name:     Function5
// keywords: function,unknown
// status:   correct
//
// Decarling a function as `class' seems to be allowed.  I wonder if
// any implementation will allow this...
//

function f
  input Real x;
  output Real y;
algorithm
  y := x * 2.0;
end f;

model Function5
  Real a,b;
equation
  a = f(b);
end Function5;

// Result:
// function f
//   input Real x;
//   output Real y;
// algorithm
//   y := 2.0 * x;
// end f;
//
// class Function5
//   Real a;
//   Real b;
// equation
//   a = f(b);
// end Function5;
// endResult
