//spaceprobe moving in the Earth-Moon-system
//from Numerical Methods for Differential Equations - A Computational Approach
//John R. Dormand
//1996 CRC Press LLC
//ISBN 0-8493-9433-3
//see p. 163 example 11
//example 1 : M = 1.0/82.45; E = 0.987871437235; x(start = 1.2); w(start = -1.049357509830320);
model SpaceProbe
  parameter Real M = 0.012277471;
  parameter Real E = 1.0 - M;
  Real r1;
  Real r2;
  Real x(start = 1.15);
  Real y(start = 0.0);
  Real u(start = 0.0);
  Real w(start = 0.0086882909);
equation
  r1 = sqrt((x + M) * (x + M) + y * y);
  r2 = sqrt((x - E) * (x - E) + y * y);
  der(x) = u;
  der(y) = w;
  der(u) = 2.0 * w + x - (E*(x + M)/(r1*r1*r1)) - (M*(x - E)/(r2*r2*r2));
  der(w) = -2.0 * u + y - ((E * y)/(r1*r1*r1)) - ((M * y) /(r2*r2*r2));
end SpaceProbe;