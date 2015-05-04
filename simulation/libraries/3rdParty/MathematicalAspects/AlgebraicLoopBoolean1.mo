model AlgebraicLoopBoolean1
  Boolean a(start=true);
  Boolean b;
  Real u;
  Real v;
equation
  u = sin(time);
  v = sin(2*time);
  b = not a and abs(u)>0.5;
  a = not b and abs(v)>0.5;
end AlgebraicLoopBoolean1;
