
record rec
  Real r;
  Integer i;
end rec;

function fn
  output rec r;
algorithm
  r.r := 1.0;
  r.i := 2;
end fn;

model mo
end mo;
