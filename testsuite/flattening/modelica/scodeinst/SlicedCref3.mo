// name: SlicedCref3
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
end R;

model SlicedCref3
  R r[3];
  Real x[3];
algorithm
  r.x := ones(3);
  x := r.x;
end SlicedCref3;

// Result:
// class SlicedCref3
//   Real r[1].x;
//   Real r[2].x;
//   Real r[3].x;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// algorithm
//   r.x := {1.0, 1.0, 1.0};
//   x := array(r[$i1].x for $i1 in 1:3);
// end SlicedCref3;
// endResult
