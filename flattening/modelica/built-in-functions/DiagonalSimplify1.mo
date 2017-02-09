// name: DiagonalSimplify1
// keywords: diagonal, simplify
// status: correct
//
// Tests simplification of built in operator diagonal.
//

model DiagonalSimplify1
  parameter Integer N = 2;
  parameter Real p[N] = ones(N);
  parameter Real m[N] = (diagonal(p) * fill(2.0,N));
end DiagonalSimplify1;

// Result:
// class DiagonalSimplify1
//   parameter Integer N = 2;
//   parameter Real p[1] = 1.0;
//   parameter Real p[2] = 1.0;
//   parameter Real m[1] = 2.0;
//   parameter Real m[2] = 2.0;
// end DiagonalSimplify1;
// endResult
