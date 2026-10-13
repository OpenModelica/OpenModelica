// name: RedeclareConstrainingType5
// keywords:
// status: correct
//
// Checks that a replaceable component inside the constraining type is not
// required to have the same type in the redeclared type, since it only needs
// to be compatible with its own constraining type.
//

model A
  Real x;
end A;

model B
  extends A;
  Real y;
end B;

model C
  extends A;
  Real z;
end C;

model Base
  replaceable B a constrainedby A;
end Base;

model Derived
  extends Base(redeclare C a);
end Derived;

model M
  replaceable Base b;
end M;

model RedeclareConstrainingType5
  M m(redeclare Derived b);
end RedeclareConstrainingType5;

// Result:
// class RedeclareConstrainingType5
//   Real m.b.a.x;
//   Real m.b.a.z;
// end RedeclareConstrainingType5;
// endResult
