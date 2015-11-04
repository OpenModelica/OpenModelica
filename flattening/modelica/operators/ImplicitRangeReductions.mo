// name:     ImplicitRangeReductions
// keywords: reductions implicit range
// status:   correct
//
// Tests deduction of implicit iteration ranges in reductions.
//

package P
  constant Real x[2] = {1, 2};
end P;

model ImplicitRangeReductions
  Real a[3] = {1, 2, 3};
  Real[3] b, c, d, f, g;
  Real[2] l, m;
  Real e[3, 3];
  R1 r1[3];
  R2 r2;
  Real h[E] = {1, 2, 3};
  Real i[E];
  Real j[Boolean] = {1, 2};
  Real k[Boolean];

  record R1
    Real x;
  end R1;

  record R2
    Real x[3];
  end R2;

  type E = enumeration(one, two, three);
equation
  b = {a[i] for i};
  c = {a[i]*a[i] for i};
  d = {b[i]+c[i] for i};
  e = {b[i]+c[j] for i, j};
  f = {r1[i].x for i};
  g = {r2.x[i] for i};
  i = {h[i] for i};
  k = {j[i] for i};
  l = {P.x[i] for i};
  m = {.P.x[i] for i};
end ImplicitRangeReductions;

// Result:
// function ImplicitRangeReductions.R1 "Automatically generated record constructor for ImplicitRangeReductions.R1"
//   input Real x;
//   output R1 res;
// end ImplicitRangeReductions.R1;
//
// function ImplicitRangeReductions.R2 "Automatically generated record constructor for ImplicitRangeReductions.R2"
//   input Real[3] x;
//   output R2 res;
// end ImplicitRangeReductions.R2;
//
// class ImplicitRangeReductions
//   Real a[1];
//   Real a[2];
//   Real a[3];
//   Real b[1];
//   Real b[2];
//   Real b[3];
//   Real c[1];
//   Real c[2];
//   Real c[3];
//   Real d[1];
//   Real d[2];
//   Real d[3];
//   Real f[1];
//   Real f[2];
//   Real f[3];
//   Real g[1];
//   Real g[2];
//   Real g[3];
//   Real l[1];
//   Real l[2];
//   Real m[1];
//   Real m[2];
//   Real e[1,1];
//   Real e[1,2];
//   Real e[1,3];
//   Real e[2,1];
//   Real e[2,2];
//   Real e[2,3];
//   Real e[3,1];
//   Real e[3,2];
//   Real e[3,3];
//   Real r1[1].x;
//   Real r1[2].x;
//   Real r1[3].x;
//   Real r2.x[1];
//   Real r2.x[2];
//   Real r2.x[3];
//   Real h[ImplicitRangeReductions.E.one];
//   Real h[ImplicitRangeReductions.E.two];
//   Real h[ImplicitRangeReductions.E.three];
//   Real i[ImplicitRangeReductions.E.one];
//   Real i[ImplicitRangeReductions.E.two];
//   Real i[ImplicitRangeReductions.E.three];
//   Real j[false];
//   Real j[true];
//   Real k[false];
//   Real k[true];
// equation
//   a = {1.0, 2.0, 3.0};
//   h = {1.0, 2.0, 3.0};
//   j = {1.0, 2.0};
//   b[1] = a[1];
//   b[2] = a[2];
//   b[3] = a[3];
//   c[1] = a[1] ^ 2.0;
//   c[2] = a[2] ^ 2.0;
//   c[3] = a[3] ^ 2.0;
//   d[1] = b[1] + c[1];
//   d[2] = b[2] + c[2];
//   d[3] = b[3] + c[3];
//   e[1,1] = b[1] + c[1];
//   e[1,2] = b[2] + c[1];
//   e[1,3] = b[3] + c[1];
//   e[2,1] = b[1] + c[2];
//   e[2,2] = b[2] + c[2];
//   e[2,3] = b[3] + c[2];
//   e[3,1] = b[1] + c[3];
//   e[3,2] = b[2] + c[3];
//   e[3,3] = b[3] + c[3];
//   f[1] = r1[1].x;
//   f[2] = r1[2].x;
//   f[3] = r1[3].x;
//   g[1] = r2.x[1];
//   g[2] = r2.x[2];
//   g[3] = r2.x[3];
//   i[ImplicitRangeReductions.E.one] = h[ImplicitRangeReductions.E.one];
//   i[ImplicitRangeReductions.E.two] = h[ImplicitRangeReductions.E.two];
//   i[ImplicitRangeReductions.E.three] = h[ImplicitRangeReductions.E.three];
//   k[false] = j[false];
//   k[true] = j[true];
//   l[1] = 1.0;
//   l[2] = 2.0;
//   m[1] = 1.0;
//   m[2] = 2.0;
// end ImplicitRangeReductions;
// [flattening/modelica/operators/ImplicitRangeReductions.mo:43:3-43:22:writable] Error: Variable i not found in scope <global scope>.
//
// endResult
