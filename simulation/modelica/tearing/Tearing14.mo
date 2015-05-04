within ;
model Tearing14
  Real source;
  Real v1(start=0);
  Real v2(start=0);
  Real v3(start=0);
  Real v4(start=0);

equation
  source = sin(time);
  v1 + v3 - 4 + source = 0;
  2*v1 + v2 - v4 - source = 0;
  3*v1 - 2*v3 + 3 * source = 0;
  3*v2 - v4 - 2 - source/2 = 0;
end Tearing14;
