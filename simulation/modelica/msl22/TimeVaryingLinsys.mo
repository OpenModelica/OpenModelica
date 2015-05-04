model TimeVaryingLinSys
  Real x,y,z,u,w;
equation
  der(u)=-4*u;
  x*der(x)+2*der(y)+3*der(z)=4;
  2*der(x)+der(y)+3*der(z)=5;
  2*der(x)+2*der(y)+der(z)=6;
  der(w)=der(x)+der(y);
end TimeVaryingLinSys;

