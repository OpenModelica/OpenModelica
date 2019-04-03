model InputOutput
  input Real u(start=1);
  input Real u2(start=2);
  output Real y;
  Real x;
equation
  der(x)=-2*x+u;
  y=x+2*u+u2;
end InputOutput;
