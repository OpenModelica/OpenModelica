
function expression_if1

  input Real x;
  output Real y;
  Real zz[2,2];
  Real z[2];
algorithm

  y := if x > 2 then (zz*z)*z else 1.0;

end expression_if1;

model mo
end mo;
