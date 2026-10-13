// name: RedeclareConstrainingType4
// keywords:
// status: correct
//
// Checks that a component can be redeclared with any subtype of the constraining
// type, also when it's not a subtype of the type of the original component or
// when the constraining type is inherited by a redeclare.
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
protected
  Real w;
end C;

model M
  replaceable B b constrainedby A;
end M;

model M2
  extends M(redeclare replaceable C b);
end M2;

model RedeclareConstrainingType4
  M m1(redeclare A b);
  M m2(redeclare C b);
  M2 m3(redeclare A b);
  extends M2(redeclare B b);
end RedeclareConstrainingType4;

// Result:
// class RedeclareConstrainingType4
//   Real m1.b.x;
//   Real m2.b.x;
//   Real m2.b.z;
//   protected Real m2.b.w;
//   Real m3.b.x;
//   Real b.x;
//   Real b.y;
// end RedeclareConstrainingType4;
// endResult
