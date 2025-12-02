// name: RedeclareMod10
// keywords:
// status: correct
//

model A
  Real x;
end A;

model B
  replaceable A a;
end B;

model C
  B b[2];
end C;

model RedeclareMod10
  extends C(b(redeclare A a(x = {1, 2})));
end RedeclareMod10;

// Result:
// class RedeclareMod10
//   Real b[1].a.x = 1.0;
//   Real b[2].a.x = 2.0;
// end RedeclareMod10;
// endResult
