record rec
  Real r;
  Integer i;
end rec;

function fn
  output rec[2] r1;
  output rec[2] r2;
algorithm
  r1.r := {1.0,2.0};
  r1.i := {1,2};

  r2.r := {1.0,2.0};
  r2.i := {1,2};
end fn;

model mo
end mo;
