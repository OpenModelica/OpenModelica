model ideal_diode
  Real v0;
  Real v1,v2;
  Real u;
  Real i1,i2;
  Real s;
  Boolean off;
  Real i0;
  parameter Real R1=1,R2=2,C=0.1;
equation

  v0 = 2*sin(7*time);

  off = s < 0;
  u = v1 - v2;
  u = if off then s else 0;
  i0 = if off then 0 else s;
  R1*i0= v0-v1;

 i2=v2/R2;
 i1 = i0-i2;
 der(v2) = i1/C;
end ideal_diode;

