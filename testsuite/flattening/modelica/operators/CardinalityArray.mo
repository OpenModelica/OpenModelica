// name:     CardinalityArray
// keywords: cardinality #2585
// status:   correct
//
// Tests the cardinality operator when arrays are involved.
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c;
end A;

model CardinalityArray
  A a1[2], a2[2];
  Integer c = cardinality(a1[1].c);
equation
  connect(a1.c, a2.c);
end CardinalityArray;

// Result:
// class CardinalityArray
//   Real a1[1].c.e;
//   Real a1[1].c.f;
//   Real a1[2].c.e;
//   Real a1[2].c.f;
//   Real a2[1].c.e;
//   Real a2[1].c.f;
//   Real a2[2].c.e;
//   Real a2[2].c.f;
//   Integer c = 1;
// equation
//   a1[2].c.f + a2[2].c.f = 0.0;
//   a1[1].c.f + a2[1].c.f = 0.0;
//   a1[1].c.e = a2[1].c.e;
//   a1[2].c.e = a2[2].c.e;
// end CardinalityArray;
// endResult
