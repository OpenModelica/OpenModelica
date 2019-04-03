model Alias
  Real a,b,c,d,e,f,g;
  Real x(start=1);
equation
  der(x) = a*x;
  a = b;
  connect(b , c);
  connect(d,e);
  -c = d;
  d = sin(time);
  g = sin(3.14159265);
  connect(f,g);
end Alias;
