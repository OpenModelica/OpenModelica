// name:     FunctionEval6
// keywords: function,constant propagation
// status:   correct
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.

function test2
  output Real x[4]={1,2,3,4};
end test2;

function test3
  output Real x = 5;
end test3;

function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 4;
end test;

model FunctionEval6
  parameter Real a=5;
  parameter Real b[3]={1,2,3};
  Real x1=test(a);
  Real x2=test(size(b,1));
  Real x3=test(test3());
  Real y;
equation
  y = test(x1+x2);
end FunctionEval6;

// Result:
// function test
//   input Real x;
//   output Real y;
// algorithm
//   y := 4.0 + x;
// end test;
//
// function test3
//   output Real x = 5.0;
// end test3;
//
// class FunctionEval6
//   parameter Real a = 5.0;
//   parameter Real b[1] = 1.0;
//   parameter Real b[2] = 2.0;
//   parameter Real b[3] = 3.0;
//   Real x1 = test(a);
//   Real x2 = 7.0;
//   Real x3 = 9.0;
//   Real y;
// equation
//   y = test(x1 + x2);
// end FunctionEval6;
// endResult
