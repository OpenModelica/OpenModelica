// name: CevalRecordArray3
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
  Real y;
  Real z;
end R;

model CevalRecordArray3
  constant R r[2](each x = 1.0, y = {2, 3}, z = {4, 5});
  Real r1[2] = r.x;
  Real r2[2] = r.y;
  Real r3[2] = r.z;
  Real r4 = r[2].x;
  Real r5 = r[1].y;
end CevalRecordArray3;

// Result:
// class CevalRecordArray3
//   constant Real r[1].x = 1.0;
//   constant Real r[1].y = 2.0;
//   constant Real r[1].z = 4.0;
//   constant Real r[2].x = 1.0;
//   constant Real r[2].y = 3.0;
//   constant Real r[2].z = 5.0;
//   Real r1[1];
//   Real r1[2];
//   Real r2[1];
//   Real r2[2];
//   Real r3[1];
//   Real r3[2];
//   Real r4 = 1.0;
//   Real r5 = 2.0;
// equation
//   r1 = {1.0, 1.0};
//   r2 = {2.0, 3.0};
//   r3 = {4.0, 5.0};
// end CevalRecordArray3;
// endResult
