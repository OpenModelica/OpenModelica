// name: SlicedCref2
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
end R;

record R2
  R r[2, 3];
end R2;

record R3
  R2 r2[4];
end R3;

function f
  input R3 r;
  output Real x[:, :, :];
algorithm
  x := r.r2.r.x;
end f;

model SlicedCref2
  R3 r3;
  Real x[:, :, :] = f(r3);
end SlicedCref2;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   output R res;
// end R;
//
// function R2 "Automatically generated record constructor for R2"
//   input R[2, 3] r;
//   output R2 res;
// end R2;
//
// function R3 "Automatically generated record constructor for R3"
//   input R2[4] r2;
//   output R3 res;
// end R3;
//
// function f
//   input R3 r;
//   output Real[:, :, :] x;
// algorithm
//   x := array(array(array(r.r2[$i3].r[$i2,$i1].x for $i1 in 1:3) for $i2 in 1:2) for $i3 in 1:4);
// end f;
//
// class SlicedCref2
//   Real r3.r2[1].r[1,1].x;
//   Real r3.r2[1].r[1,2].x;
//   Real r3.r2[1].r[1,3].x;
//   Real r3.r2[1].r[2,1].x;
//   Real r3.r2[1].r[2,2].x;
//   Real r3.r2[1].r[2,3].x;
//   Real r3.r2[2].r[1,1].x;
//   Real r3.r2[2].r[1,2].x;
//   Real r3.r2[2].r[1,3].x;
//   Real r3.r2[2].r[2,1].x;
//   Real r3.r2[2].r[2,2].x;
//   Real r3.r2[2].r[2,3].x;
//   Real r3.r2[3].r[1,1].x;
//   Real r3.r2[3].r[1,2].x;
//   Real r3.r2[3].r[1,3].x;
//   Real r3.r2[3].r[2,1].x;
//   Real r3.r2[3].r[2,2].x;
//   Real r3.r2[3].r[2,3].x;
//   Real r3.r2[4].r[1,1].x;
//   Real r3.r2[4].r[1,2].x;
//   Real r3.r2[4].r[1,3].x;
//   Real r3.r2[4].r[2,1].x;
//   Real r3.r2[4].r[2,2].x;
//   Real r3.r2[4].r[2,3].x;
//   Real x[1,1,1];
//   Real x[1,1,2];
//   Real x[1,1,3];
//   Real x[1,2,1];
//   Real x[1,2,2];
//   Real x[1,2,3];
//   Real x[2,1,1];
//   Real x[2,1,2];
//   Real x[2,1,3];
//   Real x[2,2,1];
//   Real x[2,2,2];
//   Real x[2,2,3];
//   Real x[3,1,1];
//   Real x[3,1,2];
//   Real x[3,1,3];
//   Real x[3,2,1];
//   Real x[3,2,2];
//   Real x[3,2,3];
//   Real x[4,1,1];
//   Real x[4,1,2];
//   Real x[4,1,3];
//   Real x[4,2,1];
//   Real x[4,2,2];
//   Real x[4,2,3];
// equation
//   x = f(r3);
// end SlicedCref2;
// endResult
