// name:     FunctionEval3
// keywords: function,constant propagation
// status:   correct
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica. Parameters are not
// considered as constants. Because they can be changed before each
// simulation

function f
  input  Real x;
  output Real y;
algorithm
  y := x + 2;
end f;

model FunctionEval3
  parameter Real a=5;
  Real x;
equation
  x = f(a);
end FunctionEval3;

// function f
// input Real x;
// output Real y;
// algorithm
//   y := x + 2.0;
// end f;
//


// function f
// input Real x;
// output Real y;
// algorithm
//   y := 2.0 + x;
// end f;
//
// Result:
// function f
//   input Real x;
//   output Real y;
// algorithm
//   y := 2.0 + x;
// end f;
//
// class FunctionEval3
//   parameter Real a = 5.0;
//   Real x;
// equation
//   x = f(a);
// end FunctionEval3;
// endResult
