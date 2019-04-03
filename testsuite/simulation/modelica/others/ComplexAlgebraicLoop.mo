record R
  Real x;
  Real y;
end R;

function f
  input Real t;
  output R a;
algorithm
  a.x := sin(t);
  a.y := cos(t);
end f;

model M
  R r;
  Real x,y;
  Real x1,y1;
  Real x2,y2;
equation
  x = sin(time)+1*r.x;
  y = cos(time)+1*r.x+x;
algorithm
 r := f(x);
equation
  x1 = sin(time)+1*x2;
  y1 = cos(time)+1*x2+x1;
algorithm
 x2 := sin(x1);
 y2 := cos(x1);
end M;
