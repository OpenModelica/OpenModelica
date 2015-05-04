record R
  Real x;
  Real y;
end R;

function ftest
  input Real a;
  output Real c[2];
  output Real b[2];
algorithm
  (c, b) := ftest2(a);
end ftest;

function ftest2
  input Real a;
  output Real b[2];
  output Real c[2];
algorithm
  b := {a, 2*a};
  c := {a/2, a};
end ftest2;

function ftest3
  input Real a;
  output R b;
  output R c;
algorithm
  b.x := 2*a;
  b.y := a/2;
  c.x := 3*a;
  c.y := a/3;
end ftest3;

model TupleReturn
  Real a;
  Real b[2], b1[2];
  Real c[2], c1[2];
  R r,r1;
  Real d;
equation
  a = 2;
  d = r.y;
  (b,c) = ftest(r.x);
  (,c1) = ftest(b[2]);
  (r,r1) = ftest3(c1[2]);
  (b1,) = ftest(b[2]);
end TupleReturn;
