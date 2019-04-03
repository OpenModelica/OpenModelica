model PantelidesSingular
  Real x;
  Real u1,u2;
  parameter Real y1=1;
  parameter Real y2=3;
equation
//  u1 = sin(time);
//  u2 = cos(time);

  0 = x + u1*u2;
  0 = der(x)*y1+x;
  0 = 40*x + x*x - y2;
end PantelidesSingular;
