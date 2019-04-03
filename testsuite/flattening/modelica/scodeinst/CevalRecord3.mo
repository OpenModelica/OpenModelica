// name: CevalRecord3
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
  Real y;
  Real z = 3.0;
end R;

model CevalRecord3
  constant R r1 = R(1.0, 2.0);
  Real x = r1.x;
  Real y = r1.y;
  Real z = r1.z;
end CevalRecord3;

// Result:
// class CevalRecord3
//   constant Real r1.x = 1.0;
//   constant Real r1.y = 2.0;
//   constant Real r1.z = 3.0;
//   Real x = 1.0;
//   Real y = 2.0;
//   Real z = 3.0;
// end CevalRecord3;
// endResult
