
function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 1;
end test;

model mo
  Real x;
equation
  x = test(1);
end mo;

