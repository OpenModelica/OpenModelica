// name: CevalRecord4
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x = 1.0;
  Real y = 2.0;
  Real z = 3.0;
end R;

model CevalRecord4
  constant R r1(y = 5);
  R r2 = r1;
end CevalRecord4;

// Result:
// class CevalRecord4
//   constant Real r1.x = 1.0;
//   constant Real r1.y = 5.0;
//   constant Real r1.z = 3.0;
//   Real r2.x = 1.0;
//   Real r2.y = 5.0;
//   Real r2.z = 3.0;
// end CevalRecord4;
// endResult
