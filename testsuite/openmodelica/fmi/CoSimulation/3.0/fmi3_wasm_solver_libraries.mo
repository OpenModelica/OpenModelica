model MixedSystems
  Real x(start = 1, fixed = true);
  Real a, b, c;
  Real y;
equation
  der(x) = -x + y;
  a + 2*b - c = 1 + x;
  2*a - b + c = 2;
  a - b + 3*c = sin(time);
  y^3 + y = 1 + a;
end MixedSystems;
