// Circle model

model Circle
  Real x_out;
  Real y_out;
  Real x(start=0.1);
  Real y(start=0.1);
equation
  der(x) = y;
  der(y) = x;
  x_out = x;
  y_out = y;
end Circle;
