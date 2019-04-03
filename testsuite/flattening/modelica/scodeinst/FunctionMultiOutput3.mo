// name:     FunctionMultiOutput3
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

model FunctionMultiOutput3
  Real x = f(3);
  Real y;
equation
  y = f(4);
end FunctionMultiOutput3;

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
// class FunctionMultiOutput3
//   Real x = 6.0;
//   Real y;
// equation
//   y = 8.0;
// end FunctionMultiOutput3;
// endResult
