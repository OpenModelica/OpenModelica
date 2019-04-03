within ;
model Tearing11
  "'Continuous System Simulation', Francois Cellier, Homework Problems [H7.5], p.313"
  Real u0;
  Real u1;
  Real u2;
  Real u3;
  Real u4;
  Real u5;
  Real i1;
  Real i2;
  Real i3(start=0);
  Real i4;
  Real i5(start=0);
  parameter Real R1=10;
  parameter Real R2=10;
  parameter Real R3=10;
  parameter Real R4=10;
  parameter Real R5=10;
equation
    u0 = 230*sin(2*3.14*50*time);
    i5 - i3 - i2 = 0;
    u3 = R3 * i3;
    u3 = u4 - u5;
    u2 = u0 - u5;
    u2 = R2 * i2;
    u5 = R5 * i5;
    i4 + i3 - i1 = 0;
    u1 = R1 * i1;
    u1 = u0 - u4;
    u4 = R4 * i4;
end Tearing11;
