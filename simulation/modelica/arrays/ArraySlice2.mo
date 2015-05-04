// name:     ArraySlice2
// keywords: array slicing
// status:   correct
//
// Tests array slicing where some subscripts are scalar variables.
//

function CubicSplineEval
  input Real x;
  input Real coefs[4];
  output Real y;
algorithm
  y := coefs[4] + x * (coefs[3] + x * (coefs[2] + x * coefs[1]));
end CubicSplineEval;

function f
  output Real y;
protected
  Integer int = 1;
  constant Real x[3, 4] = ones(3, 4);
algorithm
  y := CubicSplineEval(2.0, x[int, 1:4]);
end f;

model ArraySlice2
  Real y = f();
end ArraySlice2;

