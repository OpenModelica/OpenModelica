// name: RedeclareMod3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = 0.0;
  Real y = 0.0;
  Real z = 0.0;
end A;

model B
  replaceable A a(x = 1.0);
end B;

model C
  extends B(redeclare replaceable A a(y = 2.0));
end C;

model RedeclareMod3
  extends C(redeclare replaceable A a(z = 3.0));
end RedeclareMod3;

// Result:
// class RedeclareMod3
//   Real a.x = 1.0;
//   Real a.y = 0.0;
//   Real a.z = 3.0;
// end RedeclareMod3;
// endResult
