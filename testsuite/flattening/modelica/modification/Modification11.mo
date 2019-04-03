// name:     Modification11
// keywords: modification
// status:   correct
//

class B
  Real x = 1.0;
end B;

class A
  B b1;
  B b2;
end A;

class Modification11
  A a(b2(x = 17.0));
end Modification11;

// Result:
// class Modification11
//   Real a.b1.x = 1.0;
//   Real a.b2.x = 17.0;
// end Modification11;
// endResult
