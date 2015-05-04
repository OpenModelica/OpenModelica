model dae1
   Real x1;
   Real x2;
equation
   (sin(x1)*der(x1)+cos(x2)*der(x2))+x1 = 1;
   (-cos(x2)*der(x1)+sin(x1)*der(x2))+x2 = 0;
end dae1;

model dae2
   Real x1;
   Real x2;
equation
   ((der(x1)/(1+der(x1)^(2))+sin(der(x2))/(1+der(x1)^(2)))+x1*x2)+x1 = 1;
   (sin(der(x1))-der(x2)/(1+der(x1)^(2)))-(2*x1)*x2+x1 = 0;
end dae2;

model NonLinSys
  Real x(start=1);
equation
  der(x)=sin(der(x)+1)-x;
end NonLinSys;

