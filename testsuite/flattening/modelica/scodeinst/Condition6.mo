// name: Condition6
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

connector C1
  Real e;
  flow Real f;
end C1;

connector C2
  C1 c1;
  C1 c2;
end C2;

connector C3
  C1 c1 if true;
  C1 c2 if false;
end C3;

connector C4
  C1 c1 if false;
  C1 c2 if true;
end C4;

model Condition6
  C2 c2;
  C3 c3;
  C4 c4;
equation
  connect(c2, c3);
  connect(c2, c4);
  connect(c3, c4);
end Condition6;

// Result:
// class Condition6
//   Real c2.c1.e;
//   Real c2.c1.f;
//   Real c2.c2.e;
//   Real c2.c2.f;
//   Real c3.c1.e;
//   Real c3.c1.f;
//   Real c4.c2.e;
//   Real c4.c2.f;
// equation
//   c2.c1.e = c3.c1.e;
//   (-c2.c1.f) + (-c3.c1.f) = 0.0;
//   c2.c2.e = c4.c2.e;
//   (-c2.c2.f) + (-c4.c2.f) = 0.0;
//   c2.c1.f = 0.0;
//   c2.c2.f = 0.0;
//   c3.c1.f = 0.0;
//   c4.c2.f = 0.0;
// end Condition6;
// endResult
