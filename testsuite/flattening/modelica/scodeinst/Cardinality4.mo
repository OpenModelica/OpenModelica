// name: Cardinality4
// keywords: cardinality
// status: correct
//
// Tests the builtin cardinality operator.
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c;
end A;

model Cardinality4
  A a1[2], a2[2];
equation
  assert(cardinality(a1[1].c) == 1, "cardinality(a1[1].c) should be 1");
  connect(a1.c, a2.c);
end Cardinality4;

// Result:
// class Cardinality4
//   Real a1[1].c.e;
//   Real a1[1].c.f;
//   Real a1[2].c.e;
//   Real a1[2].c.f;
//   Real a2[1].c.e;
//   Real a2[1].c.f;
//   Real a2[2].c.e;
//   Real a2[2].c.f;
// equation
//   a1[1].c.e = a2[1].c.e;
//   a1[2].c.e = a2[2].c.e;
//   a2[1].c.f + a1[1].c.f = 0.0;
//   a2[2].c.f + a1[2].c.f = 0.0;
// end Cardinality4;
// endResult
