
record rec
  Real r;
  Integer i;
end rec;

function return_record
  output rec r;
algorithm
  r.r := 1.0;
  r.i := 2;
end return_record;

model mo
end mo;
