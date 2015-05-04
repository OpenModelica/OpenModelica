// name:     Modification10
// keywords: modification
// status:   correct
//
//

class B
  Real x = 1.0;
end B;

class C
  B b;
end C;

class A
  replaceable class B2=B;
  C c;
  B2 b;
end A;

class Modification10
  A a(redeclare class B2=B(x = 17.0));
end Modification10;









// Result:
// class Modification10
//   Real a.c.b.x = 1.0;
//   Real a.b.x = 17.0;
// end Modification10;
// endResult
