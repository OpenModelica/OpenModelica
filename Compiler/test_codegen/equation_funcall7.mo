
function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 4;
end test;

model mo
  parameter Real a=5;
  Real x=test(a);
  Real y;
equation
  y = test(x);
end mo;

