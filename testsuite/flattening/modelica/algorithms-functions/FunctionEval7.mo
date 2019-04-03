// name:     FunctionEval7
// keywords: function,constant propagation
// status:   correct
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.

function test2
  output Real x[4]={1,2,3,4};
end test2;

function test3
  input Real a;
  output Real x = a+5;
end test3;

function test
  input  Real x;
  output Real y;
protected
algorithm
  y := test3(x) + test3(4);
end test;

model FunctionEval7
  parameter Real a=5;
  parameter Real b=sqrt(a);
  Real x1=test(a);
  Real x3=test(test3(sin(x1)));
  Real y;
equation
  y = test(x1+x3);
end FunctionEval7;


// function test2
// output Real x;
// end test2;
//
// function test3
// input Real a;
// output Real x;
// equation
//   x = a + 5.0;
// end test3;
//
// function test
// input Real x;
// output Real y;
// algorithm
//   y := test3(x) + test3(4.0);
// end test;
//
// function test3
// input Real a;
// output Real x = 5.0 + a;
// end test3;
//
// function test
// input Real x;
// output Real y;
// algorithm
//   y := test3(x) + test3(4.0);
// end test;
//
// Result:
// function test
//   input Real x;
//   output Real y;
// algorithm
//   y := 9.0 + test3(x);
// end test;
//
// function test3
//   input Real a;
//   output Real x = 5.0 + a;
// end test3;
//
// class FunctionEval7
//   parameter Real a = 5.0;
//   parameter Real b = sqrt(a);
//   Real x1 = test(a);
//   Real x3 = test(test3(sin(x1)));
//   Real y;
// equation
//   y = test(x1 + x3);
// end FunctionEval7;
// endResult
