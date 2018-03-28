// name: RecordBinding2
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x = 1.0;
  Real y = 2.0;
  Real z = 3.0;
end R;

model RecordBinding2
  R r[2] = {R(4.0, 5.0), R(6.0, 7.0)};
end RecordBinding2;

// Result:
// class RecordBinding2
//   Real r[1].x;
//   Real r[1].y;
//   Real r[1].z;
//   Real r[2].x;
//   Real r[2].y;
//   Real r[2].z;
// equation
//   r[1] = R(4.0, 5.0, 3.0);
//   r[2] = R(6.0, 7.0, 3.0);
// end RecordBinding2;
// endResult
