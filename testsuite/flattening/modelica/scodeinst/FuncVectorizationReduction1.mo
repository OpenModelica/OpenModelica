// name: FuncVectorizationReduction1
// keywords: vectorization function reduction
// status: correct
//
// A reduction of a vectorized call over a matrix becomes a reduction with one
// iterator for each dimension, without a temporary array.
//

model FuncVectorizationReduction1
  function f
    input Real x[:, :];
    output Real y1;
    output Real y2;
  algorithm
    y1 := max(abs(x));
    y2 := sum(abs(x));
  end f;

  Real y1, y2;
equation
  (y1, y2) = f({{time, -2}, {3, -4*time}});
end FuncVectorizationReduction1;

// Result:
// function FuncVectorizationReduction1.f
//   input Real[:, :] x;
//   output Real y1;
//   output Real y2;
// algorithm
//   y1 := max(max(abs(x[$i0,$i1]) for $i1 in 1:size(x, 2)) for $i0 in 1:size(x, 1));
//   y2 := sum(sum(abs(x[$i2,$i3]) for $i3 in 1:size(x, 2)) for $i2 in 1:size(x, 1));
// end FuncVectorizationReduction1.f;
//
// class FuncVectorizationReduction1
//   Real y1;
//   Real y2;
// equation
//   (y1, y2) = FuncVectorizationReduction1.f({{time, -2.0}, {3.0, -4.0 * time}});
// end FuncVectorizationReduction1;
// endResult
