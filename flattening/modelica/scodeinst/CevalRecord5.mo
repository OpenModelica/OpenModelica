// name: CevalRecord5
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x = 1.0;
  Real y = 2.0;
  Real z = 3.0;
end R;

model CevalRecord5
  constant R r1 = R(4.0, 5.0, 6.0);
  Real x = r1.x;
end CevalRecord5;

// Result:
// class CevalRecord5
//   constant Real r1.x = 4.0;
//   constant Real r1.y = 5.0;
//   constant Real r1.z = 6.0;
//   Real x = 4.0;
// end CevalRecord5;
// endResult
