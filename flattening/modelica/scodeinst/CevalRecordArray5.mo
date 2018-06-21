// name: CevalRecordArray5
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
  Real y;
  Real z;
end R;

model CevalRecordArray5
  constant R r[1] = {R(1.0, 2.0, 3.0)};
  Real r1 = r[1].x;
  Real r2 = r[1].y;
  Real r3 = r[1].z;
  Real r4[1] = r.x;
  Real r5[1] = r.y;
  Real r6[1] = r.z;
end CevalRecordArray5;

// Result:
// class CevalRecordArray5
//   constant Real r[1].x = 1.0;
//   constant Real r[1].y = 2.0;
//   constant Real r[1].z = 3.0;
//   Real r1 = 1.0;
//   Real r2 = 2.0;
//   Real r3 = 3.0;
//   Real r4[1];
//   Real r5[1];
//   Real r6[1];
// equation
//   r4 = {1.0};
//   r5 = {2.0};
//   r6 = {3.0};
// end CevalRecordArray5;
// endResult
