// name: FuncVectorizationSize1
// keywords: vectorization function size
// status: correct
//
// The range of a vectorized call with an unknown dimension takes the size from
// a part of the argument, so that the argument is not evaluated only to get its
// size. A function output whose size depends on a protected variable of the
// function has an unknown size in the caller.
//

model FuncVectorizationSize1
  function g
    input Real x[:];
    input Integer m = size(x, 1) + 1;
    output Real y[m] = fill(x[1], m);
  end g;

  function h
    input Real x[:];
    output Real y[size(x, 1)] = 2*x;
  end h;

  function p
    input Real x[:];
    output Real y[n];
  protected
    Integer n = 2*size(x, 1);
  algorithm
    y := cat(1, x, x);
  end p;

  function f
    input Real v[:, :];
    input Real x[:];
    input Integer n;
    output Real Y[size(v, 1), n];
    output Real y[4];
  algorithm
    Y := abs(v[:, 2:n + 1]);
    y[1] := max(abs(h(g(x))));
    y[2] := max(abs(p(x)));
    y[3] := size(p(x), 1);
    y[4] := sum(abs(v[1, :]));
  end f;

  Real Y[2, 2], y[4];
equation
  (Y, y) = f({{time, 2, 3}, {4, 5, time}}, {time, 2}, 2);
end FuncVectorizationSize1;

// Result:
// function FuncVectorizationSize1.f
//   input Real[:, :] v;
//   input Real[:] x;
//   input Integer n;
//   output Real[size(v, 1), n] Y;
//   output Real[4] y;
// algorithm
//   Y := array(array(abs(v[$i0,$i1 + 1]) for $i1 in 1:max(n + 1 - 2 + 1, 0)) for $i0 in 1:size(v, 1));
//   y[1] := let $let3 = FuncVectorizationSize1.h(FuncVectorizationSize1.g(x, size(x, 1) + 1)) in max(abs($let3[$i2]) for $i2 in 1:size(x, 1) + 1);
//   y[2] := let $let5 = FuncVectorizationSize1.p(x) in max(abs($let5[$i4]) for $i4 in 1:size($let5, 1));
//   y[3] := /*Real*/(size(FuncVectorizationSize1.p(x), 1));
//   y[4] := sum(abs(v[1,$i6]) for $i6 in 1:size(v, 2));
// end FuncVectorizationSize1.f;
//
// function FuncVectorizationSize1.g
//   input Real[:] x;
//   input Integer m = size(x, 1) + 1;
//   output Real[m] y = fill(x[1], m);
// end FuncVectorizationSize1.g;
//
// function FuncVectorizationSize1.h
//   input Real[:] x;
//   output Real[size(x, 1)] y = x * 2.0;
// end FuncVectorizationSize1.h;
//
// function FuncVectorizationSize1.p
//   input Real[:] x;
//   output Real[n] y;
//   protected Integer n = 2 * size(x, 1);
// algorithm
//   y := cat(1, x, x);
// end FuncVectorizationSize1.p;
//
// class FuncVectorizationSize1
//   Real Y[1,1];
//   Real Y[1,2];
//   Real Y[2,1];
//   Real Y[2,2];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
// equation
//   (Y, y) = FuncVectorizationSize1.f({{time, 2.0, 3.0}, {4.0, 5.0, time}}, {time, 2.0}, 2);
// end FuncVectorizationSize1;
// endResult
