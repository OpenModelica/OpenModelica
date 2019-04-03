model Tearing4 "Example from Book Continous System Simulation by F. Cellier page 299 "
  Real x(start=1,fixed=true);
  Real y(start=2);
  Real vX(start=3,fixed=true);
  Real vY(start=4);
  Real F(start=0);
  parameter Real m = 1;
  parameter Real l = 2;
  parameter Real g = 9.81;
  Real k;
equation
  m*der(vX) = -F*x/l;
  m*der(vY) = m*g-F*y/l;
  der(x) = vX;
  der(y) = vY;
  x^2+y^2 = l^2;
  k = x^2 + y^2;
end Tearing4;
