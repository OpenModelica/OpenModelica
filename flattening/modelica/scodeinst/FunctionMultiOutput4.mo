// name:     FunctionMultiOutput4
// keywords: 
// status:   correct
//

function f
  input Real x;
  output Real y;
  output Real z;
algorithm
  y := x * 2;
  z := x * 3;
end f;

model FunctionMultiOutput4
  Real x;
equation
  x = f(time) + 1;
end FunctionMultiOutput4;

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
// class FunctionMultiOutput4
//   Real x;
// equation
//   x = 1.0 + f(time)[1];
// end FunctionMultiOutput4;
// endResult
