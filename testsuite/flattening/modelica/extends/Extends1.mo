// name:     Extends1
// keywords: extends
// status:   correct
//
// Testing extends clauses

class A
  Real a = 1.0;
end A;

class B
  extends A(a = 2.0);
  Real b = 2.0;
end B;

model Extends1
  B x;
end Extends1;

// Result:
// class Extends1
//   Real x.a = 2.0;
//   Real x.b = 2.0;
// end Extends1;
// endResult
