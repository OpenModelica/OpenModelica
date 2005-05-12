record rec
  Real r;
  Integer i;
end rec;

function return_multiple_record
  output rec r1;
  output rec r2;
algorithm
  r1.r := 1.0;
  r1.i := 1;

  r2.r := 1.0;
  r2.i := 1;
end return_multiple_record;

model mo
end mo;
