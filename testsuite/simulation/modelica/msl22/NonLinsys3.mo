model NonLinSys3
  Real x(start=1);
  Real y(start=2);
equation
  der(x)=sin(der(x)+1)-x+der(y);
  der(y)=der(x)*sqrt(der(y)+1);
end NonLinSys3;

