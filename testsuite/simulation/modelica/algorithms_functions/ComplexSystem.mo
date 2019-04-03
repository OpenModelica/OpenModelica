record R
  Real x;
  Real y;
end R;

function f
  input Real x;
  input Real y;
  output R r;
algorithm
  r.x := x;
  r.y := y;
end f;

model ComplexSystem
  R r;
  Real x;
  Real y;
equation
  x = 2 - r.x;
  y = 4 - r.y;
  r = f(x,y);
  /*
  x = 1
  y = 2
  */
end ComplexSystem;