// name: CevalRecord6
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x = 1.0;
  Real y;
  Real z = 3.0;
end R;

model CevalRecord6
  constant R r1;
  Real x = r1.x;
  Real z = r1.z;
end CevalRecord6;

// Result:
// class CevalRecord6
//   constant Real r1.x = 1.0;
//   constant Real r1.y;
//   constant Real r1.z = 3.0;
//   Real x = 1.0;
//   Real z = 3.0;
// end CevalRecord6;
// endResult
