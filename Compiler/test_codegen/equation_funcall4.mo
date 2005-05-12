
function test
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 4;
end test;

model mo
  Real x;
  Real y;
equation
  y = test(x);
  x = 5;
end mo;

