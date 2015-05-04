model Tearing5 "Example Homework Problems [H7.5] from Book Continous System Simulation by F. Cellier page 313"
  Real u0(start=1),u1(start=1),u2(start=1),u3(start=1),u4(start=1),u5(start=1);
  Real i1(start=1),i2(start=1),i3(start=1),i4(start=1),i5(start=1);
  parameter Real R1=1;
  parameter Real R2=2;
  parameter Real R3=3;
  parameter Real R4=4;
  parameter Real R5=5;
 equation
  u0 = cos(time);
  u1 = R1*i1;
  u2 = R2*i2;
  u3 = R3*i3;
  u4 = R4*i4;
  u5 = R5*i5;
  i1 = i3 + i4;
  i2 + i3 = i5;
  u0 = u1 + u4;
  u1 + u3 = u2;
  u4 = u3 + u5;
end Tearing5;
