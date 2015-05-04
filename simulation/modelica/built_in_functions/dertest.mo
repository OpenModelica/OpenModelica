model dertest
  Real x(start=10),y(start=-1);
  parameter Real P=1;
equation
  der(x*y+P)=4;
  der(x+2*y*P)=-x;

end dertest;
