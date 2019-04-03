// name: CevalRecord2
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
  Real y;
  Real z;
end R;

model CevalRecord2
  constant R r1 = R(1.0, 2.0, 3.0);
  R r2 = r1;
end CevalRecord2;

// Result:
// class CevalRecord2
//   constant Real r1.x = 1.0;
//   constant Real r1.y = 2.0;
//   constant Real r1.z = 3.0;
//   Real r2.x = 1.0;
//   Real r2.y = 2.0;
//   Real r2.z = 3.0;
// end CevalRecord2;
// endResult
