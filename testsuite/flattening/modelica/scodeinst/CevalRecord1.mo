// name: CevalRecord1
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x = 1.0;
  Real y = 2.0;
  Real z = 3.0;
end R;

model CevalRecord1
  constant R r1;
  Real x = r1.x;
  Real y = r1.y;
end CevalRecord1;

// Result:
// class CevalRecord1
//   constant Real r1.x = 1.0;
//   constant Real r1.y = 2.0;
//   constant Real r1.z = 3.0;
//   Real x = 1.0;
//   Real y = 2.0;
// end CevalRecord1;
// endResult
