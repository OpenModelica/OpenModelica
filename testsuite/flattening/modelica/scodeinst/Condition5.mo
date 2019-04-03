// name: Condition5
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

connector C
  Real e;
  flow Real f;
end C;

model Condition5
  C c1;
  C c2;
  C c3 if false;
equation
  connect(c1, c2);
  connect(c2, c3);
  connect(c3, c1);
end Condition5;

// Result:
// class Condition5
//   Real c1.e;
//   Real c1.f;
//   Real c2.e;
//   Real c2.f;
// equation
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.f = 0.0;
//   c2.f = 0.0;
// end Condition5;
// endResult
