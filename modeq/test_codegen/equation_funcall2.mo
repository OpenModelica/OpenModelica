
function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 1;
end test;

model mo
  constant Real a=5;
  Real x;
equation
  x = test(a);
end mo;

