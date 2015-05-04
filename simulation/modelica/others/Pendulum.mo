model Pendulum
  parameter Real m=0.5;
  parameter Real g=9.82;
  parameter Real L=1;
  Real x(start=L),y(start=0),xd,yd;
  Real Fo;
equation
  der(y)=yd;
  der(x)=xd;
  m*der(xd) = -x*Fo/L;
  m*der(yd) = -m*g-Fo*y/L;
  x*x+y*y=L^2;
end Pendulum;

