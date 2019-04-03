model CurtissHirschfelder
  Real y(start = 0, fixed=true);
  Real z;
  parameter Real a = 50;
  parameter Real y0 = a ^ 2 / (a ^ 2 + 1);
  parameter Real b(fixed = false);
initial equation
  y = z;
equation
  der(y) = -a * (y - cos(time));
  z = a / (a ^ 2 + 1) * (a * cos(time) + sin(time)) + b * exp(-a * time);
end CurtissHirschfelder;

