
function t
  input  Real x;
  output Real y;
protected
algorithm
  y := x + 1;
end t;

model mo
  Real x;
equation
  x = 1;

end mo;

