
function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 1;
end test;

model mo
  parameter Real b = test(3);
  Real x;
equation
  x = b;
end mo;

