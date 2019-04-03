model HelloFMIWorld
  Real x(start=1);
  parameter Real a =2;
equation
  der(x) = a*x;
end HelloFMIWorld;