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
//   Real h[E.one];
//   Real h[E.two];
//   Real h[E.three];
//   Real i[E.one];
//   Real i[E.two];
//   Real i[E.three];
//   Real j[false];
//   Real j[true];
//   Real k[false];
//   Real k[true];
// equation
//   a = {1.0, 2.0, 3.0};
//   h = {1.0, 2.0, 3.0};
//   j = {1.0, 2.0};
//   b = array(a[i] for i in 1:3);
//   c = array(a[i] * a[i] for i in 1:3);
//   d = array(b[i] + c[i] for i in 1:3);
//   e = array(array(b[i] + c[j] for i in 1:3) for j in 1:3);
//   f = array(r1[i].x for i in 1:3);
//   g = array(r2.x[i] for i in 1:3);
//   i = array(h[i] for i in E.one:E.three);
//   k = array(j[i] for i in false:true);
//   l[1] = 1.0;
//   l[2] = 2.0;
//   m[1] = 1.0;
//   m[2] = 2.0;
// end ImplicitRangeReductions;
// endResult
