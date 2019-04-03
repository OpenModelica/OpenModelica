model Algorithm1
Real x0;
Real x[2];
Real y;
Real z;
Real a;
Real b;
Real c;

algorithm
  a:=z;
  b:=2*a;
  c:=5+7*b+x[1];

equation
  x0 = sin(time) * c;
  x = {2*x0+y,2*y+z};
  y = x[2] +z;
  z = 2*z +x[1] +time;
end Algorithm1;
