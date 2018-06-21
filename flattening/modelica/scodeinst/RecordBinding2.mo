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
//   Real r[1].x = 4.0;
//   Real r[1].y = 5.0;
//   Real r[1].z = 3.0;
//   Real r[2].x = 6.0;
//   Real r[2].y = 7.0;
//   Real r[2].z = 3.0;
// end RecordBinding2;
// endResult
