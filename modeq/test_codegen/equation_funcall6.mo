
function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 3;
end test;

model mo
  constant Real a=7;
  parameter Real b = test(a);
  Real x;
equation
  x = b;
end mo;

