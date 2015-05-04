model TestKV
  Real x;
  parameter Real a=2.0;
  Real s;
equation
  der(x) = a*x+s;
  s = sin(2.0)+a;
end TestKV;
