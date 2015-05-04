class SemiLinearTest
  parameter Real a=1;
  parameter Real b=2;

  Real c;
  Real x(start=5);
equation
  der(x) = -1;
  c = semiLinear(x,a,b);
end SemiLinearTest;
