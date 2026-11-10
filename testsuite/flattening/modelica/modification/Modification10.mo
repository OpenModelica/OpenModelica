// name:     Modification10
// keywords: modification
// status:   correct
//
//

model B
  Real x = 1.0;
end B;

model C
  B b;
end C;

model A
  replaceable model B2=B;
  C c;
  B2 b;
end A;

model Modification10
  A a(redeclare model B2=B(x = 17.0));
end Modification10;









// Result:
// class Modification10
//   Real a.c.b.x = 1.0;
//   Real a.b.x = 17.0;
// end Modification10;
// endResult
