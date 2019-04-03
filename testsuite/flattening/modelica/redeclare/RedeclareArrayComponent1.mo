// name:     RedeclareArrayComponent1
// keywords: redeclare component array
// status:   correct
//
// Checks that a redeclared components gets get correct type when using an array
// type.
//

model A
  replaceable Real x[2];
end A;

model RedeclareArrayComponent1
  type Real3 = Real[3];
  A a1(redeclare Real3 x);
  A a2(redeclare Real x);
end RedeclareArrayComponent1;

// Result:
// class RedeclareArrayComponent1
//   Real a1.x[1];
//   Real a1.x[2];
//   Real a1.x[3];
//   Real a2.x[1];
//   Real a2.x[2];
// end RedeclareArrayComponent1;
// endResult
