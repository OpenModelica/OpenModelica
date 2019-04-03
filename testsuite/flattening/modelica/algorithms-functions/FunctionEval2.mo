// name:     FunctionEval2
// keywords: function,constant propagation
// status:   correct
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.
//

function f
  input  Real x;
  output Real y;
algorithm
  y := x + 1;
end f;

model FunctionEval2
  constant Real a=5;
  Real x;
equation
  x = f(a);
end FunctionEval2;


// function f
// input Real x;
// output Real y;
// algorithm
//   y := x + 1.0;
// end f;
//
// function f
// input Real x;
// output Real y;
// algorithm
//   y := 1.0 + x;
// end f;
//
// Result:
// function f
//   input Real x;
//   output Real y;
// algorithm
//   y := 1.0 + x;
// end f;
//
// class FunctionEval2
//   constant Real a = 5.0;
//   Real x;
// equation
//   x = 6.0;
// end FunctionEval2;
// endResult
