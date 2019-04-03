model LinSys
  Real x(start=1);
  Real y(start=2);
  Real z(start=3);
equation
   der(x) + z*der(y) + der(z) = 1;
   z*der(y)-x*der(z) = 3;
   der(z)+der(x)-x*der(y) = 1;
end LinSys;
