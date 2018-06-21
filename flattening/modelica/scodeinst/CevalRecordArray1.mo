// name: CevalRecordArray1
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
  Real y;
  Real z;
end R;

model CevalRecordArray1
  constant R r[2] = {R(1.0, 2.0, 3.0), R(4.0, 5.0, 6.0)};
  Real x[2] = r.x;
  Real y[2] = r.y;
  Real z[2] = r.z;
end CevalRecordArray1;

// Result:
// class CevalRecordArray1
//   constant Real r[1].x = 1.0;
//   constant Real r[1].y = 2.0;
//   constant Real r[1].z = 3.0;
//   constant Real r[2].x = 4.0;
//   constant Real r[2].y = 5.0;
//   constant Real r[2].z = 6.0;
//   Real x[1];
//   Real x[2];
//   Real y[1];
//   Real y[2];
//   Real z[1];
//   Real z[2];
// equation
//   x = {1.0, 4.0};
//   y = {2.0, 5.0};
//   z = {3.0, 6.0};
// end CevalRecordArray1;
// endResult
