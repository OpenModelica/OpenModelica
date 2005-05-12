
function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 2;
end test;

model mo
  parameter Real a=5;
  Real x;
equation
  x = test(a);
end mo;

