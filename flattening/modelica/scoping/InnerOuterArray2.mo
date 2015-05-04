// name:     InnerOuterArray2
// keywords: dynamic scope, inner outer, lookup, array
// status:   correct
//
// Tests that inner/outer arrays are handled correctly.
//

record R
  Real X;
  Real Y;
  Real Z;
end R;

model A
  outer R r[3];
  Real y;
equation
  y = r[1].X ^ 2;
end A;

model B
  outer R r[3];
equation
  r.X = {1, 4, 7};
  r.Y = {2, 5, 8};
  r.Z = {3, 6, 9};
end B;

model InnerOuterArray2
  A a;
  B b;
  inner R r[3] = {R(0, 0, 0), R(0, 0, 0), R(0, 0, 0)};
end InnerOuterArray2;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real X;
//   input Real Y;
//   input Real Z;
//   output R res;
// end R;
//
// class InnerOuterArray2
//   Real a.y;
//   Real r[1].X = 0.0;
//   Real r[1].Y = 0.0;
//   Real r[1].Z = 0.0;
//   Real r[2].X = 0.0;
//   Real r[2].Y = 0.0;
//   Real r[2].Z = 0.0;
//   Real r[3].X = 0.0;
//   Real r[3].Y = 0.0;
//   Real r[3].Z = 0.0;
// equation
//   a.y = r[1].X ^ 2.0;
//   r[1].X = 1.0;
//   r[2].X = 4.0;
//   r[3].X = 7.0;
//   r[1].Y = 2.0;
//   r[2].Y = 5.0;
//   r[3].Y = 8.0;
//   r[1].Z = 3.0;
//   r[2].Z = 6.0;
//   r[3].Z = 9.0;
// end InnerOuterArray2;
// endResult
