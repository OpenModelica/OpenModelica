// name: CevalRecordArray4
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x = 1.0;
  Real y = 2.0;
  Real z = 3.0;
end R;

model CevalRecordArray4
  constant R r1[2];
  Real x = r1[1].x;
  Real y = r1[2].y;
end CevalRecordArray4;

// Result:
// class CevalRecordArray4
//   constant Real r1[1].x = 1.0;
//   constant Real r1[1].y = 2.0;
//   constant Real r1[1].z = 3.0;
//   constant Real r1[2].x = 1.0;
//   constant Real r1[2].y = 2.0;
//   constant Real r1[2].z = 3.0;
//   Real x = 1.0;
//   Real y = 2.0;
// end CevalRecordArray4;
// endResult
