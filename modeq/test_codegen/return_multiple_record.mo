record rec
  Real r;
  Integer i;
end rec;

function fn
  output rec r1;
  output rec r2;
algorithm
  r1.r := 1.0;
  r1.i := 1;

  r2.r := 1.0;
  r2.i := 1;
end fn;

model mo
end mo;
