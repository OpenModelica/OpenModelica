// name:     FunctionEval9
// keywords: function,constant propagation
// status:   correct
// cflags: -d=-newInst
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.


function test2
  input Real a[3];
  output Real b[4];
algorithm
  for i in 1:3 loop
    b[i] := a[i]*2;
  end for;
  b[4]:=3;
end test2;

function test3
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 7;
end test3;

function test
  input  Real x;
  output Real y;
protected
algorithm
  y := cos(x) + 4;
end test;

model FunctionEval9
  parameter Real a=5;
  parameter Real b[3]={1,2,3};
  Real x1=test(a);
  parameter Real x2=size(test2(b),1);
  Real y;
  Real z;
equation
  y = test3(x1+x2);
  z = test(y);
end FunctionEval9;



// function test2
// input Real a;
// output Real b;
// algorithm
//   for i in 1:3 loop
//     b[i] := a[i] * 2.0;
//   end for;
//   b[4] := 3.0;
// end test2;
//
// function test3
// input Real x;
// output Real y;
// algorithm
//   y := x + 7.0;
// end test3;
//
// function test
// input Real x;
// output Real y;
// algorithm
//   y := cos(x) + 4.0;
// end test;
//
// function test2
// input Real[3] a;
// output Real[4] b;
// algorithm
//   for i in 1:3 loop
//     b[i] := 2.0 * a[i];
//   end for;
//   b[4] := 3.0;
// end test2;
//
// function test
// input Real x;
// output Real y;
// algorithm
//   y := 4.0 + cos(x);
// end test;
//
// function test3
// input Real x;
// output Real y;
// algorithm
//   y := 7.0 + x;
// end test3;
//
// Result:
// function test
//   input Real x;
//   output Real y;
// algorithm
//   y := 4.0 + cos(x);
// end test;
//
// function test2
//   input Real[3] a;
//   output Real[4] b;
// algorithm
//   for i in 1:3 loop
//     b[i] := 2.0 * a[i];
//   end for;
//   b[4] := 3.0;
// end test2;
//
// function test3
//   input Real x;
//   output Real y;
// algorithm
//   y := 7.0 + x;
// end test3;
//
// class FunctionEval9
//   parameter Real a = 5.0;
//   parameter Real b[1] = 1.0;
//   parameter Real b[2] = 2.0;
//   parameter Real b[3] = 3.0;
//   Real x1 = test(a);
//   parameter Real x2 = 4.0;
//   Real y;
//   Real z;
// equation
//   y = test3(x1 + x2);
//   z = test(y);
// end FunctionEval9;
// endResult
