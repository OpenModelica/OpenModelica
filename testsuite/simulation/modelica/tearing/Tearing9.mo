model Tearing9
  Real x1;
  Real x2(start=0);
  Real x3;
  Real x4;
  Real x5(start=0);
  parameter Real X=2;
  parameter Real Y=6;
equation
  x1 + x4 -5 = 0;
  X*x3 - Y = 0;
  x2 - 2*x4 + x5 +1 = 0;
  x1*x1 - x3 +2 = 0;
  x1 - x2*x2 + x5 -2 = 0;
end Tearing9;
