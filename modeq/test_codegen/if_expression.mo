
function if_expression

  input Real x;
  output Real y;
  Real zz[2,2];
  Real z[2];
algorithm

  y := if x > 2 then (zz*z)*z else 1.0;

end if_expression;

model mo
end mo;
