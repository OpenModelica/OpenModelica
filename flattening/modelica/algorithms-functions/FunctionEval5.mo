// name:     FunctionEval5
// keywords: function,constant propagation
// status:   correct
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.
// Not implemented correctly yet.

function test2
  input Real a[:];
  output Real b[size(a,1)];
algorithm
  for i in 1:size(a,1) loop
    b[i] := a[i]*2;
  end for;
end test2;

function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 4;
end test;

model FunctionEval5
  parameter Real a=5;
  parameter Real b[3]={1,2,3};
  Real x1=test(a);
  Real x2=test(size(b,1));
  Real x3=test(size(test2(b),1));
  Real y;
equation
  y = test(x1+x2);
end FunctionEval5;
