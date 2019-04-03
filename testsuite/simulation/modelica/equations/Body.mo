//within Astronomy;

model Body "A planet or something"
  Real x;
  Real y "coordinates";
  Real vx;
  Real vy "velocity";
  Real fx;
  Real fy "force";
  parameter Real mass;
equation
  der(x) = vx;
  der(y) = vy;
  fx = mass * der(vx);
  fy = mass * der(vy);
end Body;
