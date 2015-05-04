model SingularModel2
  parameter Real a=1;
  parameter Real b=1;
  Real x(start=-1);
  Real y(start=1);
equation
  a*der(x) + b*der(y) = sin(time);
  der(x) + der(y) = cos(time);
end SingularModel2;
