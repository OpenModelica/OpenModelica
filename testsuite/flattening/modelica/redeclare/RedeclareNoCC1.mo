// name:     RedeclareNoCC1
// keywords: redeclare, constraining class, #3528
// status:   correct
//
// Checks that redeclares are applied correctly when no constraining class is
// given.
//

model A
  Real x = 1.0;
end A;

model B
  Real x = 1.0;
  Real y = 2.0;
end B;

model C
  Real x = 3.0;
end C;

model D
  replaceable A a;
end D;

model E
  extends D(redeclare replaceable B a(y = 3.0));
end E;

model F
  extends E(redeclare replaceable C a(x = 4.0));
end F;

// Result:
// class F
//   Real a.x = 4.0;
// end F;
// endResult
