

function return_multiple_scalar_array
  output Real[2] r;
  output Integer[2] i;
algorithm
  r := {1.0,2.0};
  i := {1,2};
end return_multiple_scalar_array;

model mo
end mo;
