record rec
  Real r;
  Integer i;
end rec;

function return_multiple_record_array
  output rec[2] r1;
  output rec[2] r2;
algorithm
  r1.r := {1.0,2.0};
  r1.i := {1,2};

  r2.r := {1.0,2.0};
  r2.i := {1,2};
end return_multiple_record_array;

model mo
end mo;
