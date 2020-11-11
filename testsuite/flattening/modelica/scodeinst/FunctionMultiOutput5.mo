// name:     FunctionMultiOutput5
// keywords:
// status:   correct
// cflags: -d=-newInst
//

function f
  input Real x;
  output Real y;
  output Real z;
algorithm
  y := x * 2;
  z := x * 3;
end f;

model A
  Real x;
equation
  (x, ) = f(time);
end A;

model FunctionMultiOutput5
  A a;
end FunctionMultiOutput5;

//model FunctionMultiOutput4
//  Real x;
//equation
//  x = f(time) + 1;
//end FunctionMultiOutput4;

// Result:
// function f
//   input Real x;
//   output Real y;
//   output Real z;
// algorithm
//   y := 2.0 * x;
//   z := 3.0 * x;
// end f;
//
// class FunctionMultiOutput5
//   Real a.x;
// equation
//   (a.x, _) = f(time);
// end FunctionMultiOutput5;
// endResult
