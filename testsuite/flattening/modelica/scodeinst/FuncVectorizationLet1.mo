// name: FuncVectorizationLet1
// keywords: vectorization function let
// status: correct
//
// A vectorized call in a function binds a part of an argument that cannot take
// the subscript of the iterator, so that it is evaluated one time. A part in a
// branch of an if-expression is not bound.
//

model FuncVectorizationLet1
  function g
    input Real x[:];
    output Real y[size(x, 1)] = 2*x;
  end g;

  function h
    input Real x[:];
    output Real y[:];
  algorithm
    y := cat(1, x, x);
  end h;

  function gm
    input Real x[:];
    input Integer k;
    output Real y[size(x, 1), 2];
  algorithm
    y := k*[x, x];
  end gm;

  function f
    input Real x[:];
    input Real A[:, :];
    output Real y[5];
  algorithm
    y[1] := max(abs(g(x)));
    y[2] := max(abs(h(x)));
    y[3] := max(abs(transpose(A)));
    y[4] := max(abs(sum(gm(x, k) for k in 1:2)));
    y[5] := max(abs(if x[1] > 100 then g(x) else x));
  end f;

  Real y[5] = f({time, -2*time}, {{time, 1}, {2, -time}});
end FuncVectorizationLet1;

// Result:
// function FuncVectorizationLet1.f
//   input Real[:] x;
//   input Real[:, :] A;
//   output Real[5] y;
// algorithm
//   y[1] := let $let1 = FuncVectorizationLet1.g(x) in max(abs($let1[$i0]) for $i0 in 1:size(x, 1));
//   y[2] := let $let3 = FuncVectorizationLet1.h(x) in max(abs($let3[$i2]) for $i2 in 1:size($let3, 1));
//   y[3] := let $let6 = transpose(A) in max(max(abs($let6[$i4,$i5]) for $i5 in 1:size($let6, 2)) for $i4 in 1:size($let6, 1));
//   y[4] := let $let9 = sum(FuncVectorizationLet1.gm(x, k) for k in 1:2) in max(max(abs($let9[$i7,$i8]) for $i8 in 1:2) for $i7 in 1:size(x, 1));
//   y[5] := max(abs(if x[1] > 100.0 then FuncVectorizationLet1.g(x)[$i10] else x[$i10]) for $i10 in 1:size(if x[1] > 100.0 then FuncVectorizationLet1.g(x) else x, 1));
// end FuncVectorizationLet1.f;
//
// function FuncVectorizationLet1.g
//   input Real[:] x;
//   output Real[size(x, 1)] y = x * 2.0;
// end FuncVectorizationLet1.g;
//
// function FuncVectorizationLet1.gm
//   input Real[:] x;
//   input Integer k;
//   output Real[size(x, 1), 2] y;
// algorithm
//   y := cat(2, promote(x, 2), promote(x, 2)) * /*Real*/(k);
// end FuncVectorizationLet1.gm;
//
// function FuncVectorizationLet1.h
//   input Real[:] x;
//   output Real[:] y;
// algorithm
//   y := cat(1, x, x);
// end FuncVectorizationLet1.h;
//
// class FuncVectorizationLet1
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
//   Real y[5];
// equation
//   y = FuncVectorizationLet1.f({time, -2.0 * time}, {{time, 1.0}, {2.0, -time}});
// end FuncVectorizationLet1;
// endResult
