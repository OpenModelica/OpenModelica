model Tearing3 "Example from Book Continous System Simulation by F. Cellier page 277"
  Real u0;
  Real u1;
  Real u2;
  Real uL;
  Real uC;
  Real i0;
  Real i1;
  Real i2(start=0,fixed=true);
  Real iL;
  Real iC;
  parameter Real R1=1;
  parameter Real R2=2;
  parameter Real L=0.5;
  parameter Real C=3;
equation
  u0 = sin(time);
  u1 = R1*i1;
  u2 = R2*i2;
  uL = L*der(iL);
  iC = C*der(uC);
  u0 = u1 + uL;
  uC = u1 + u2;
  uL = u2;
  i0 = i1 + iC;
  i1 = i2 + iL;
end Tearing3;
