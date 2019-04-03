// name:     FunctionEval4
// keywords: function,constant propagation
// status:   correct
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.

function f
  input  Real x;
  output Real y;
algorithm
  y := x + 4;
end f;

model FunctionEval4
  Real x;
  Real y;
equation
  y = f(x);
  x = 5;
end FunctionEval4;

// function f
// input Real x;
// output Real y;
// algorithm
//   y := x + 4.0;
// end f;
//
// Result:
// function f
//   input Real x;
//   output Real y;
// algorithm
//   y := 4.0 + x;
// end f;
//
// class FunctionEval4
//   Real x;
//   Real y;
// equation
//   y = f(x);
//   x = 5.0;
// end FunctionEval4;
// endResult
