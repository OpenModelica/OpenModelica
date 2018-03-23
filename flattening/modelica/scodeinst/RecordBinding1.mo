// name: RecordBinding1
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x = 1.0;
  Real y = 2.0;
  Real z = 3.0;
end R;

model RecordBinding1
  R r = R(4.0, 5.0);
end RecordBinding1;

// Result:
// class RecordBinding1
//   Real r.x = 4.0;
//   Real r.y = 5.0;
//   Real r.z = 3.0;
// end RecordBinding1;
// endResult
