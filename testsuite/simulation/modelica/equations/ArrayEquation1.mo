record R
  parameter String components[:];
  parameter Integer n = size(components, 1);
end R;

function f
  input R r;
  output Real x[r.n] = ones(r.n);
end f;

model ArrayEquation1
  parameter R r(components = {"a", "b"});
  Real x[r.n];
equation
  x = f(r);
end ArrayEquation1;
