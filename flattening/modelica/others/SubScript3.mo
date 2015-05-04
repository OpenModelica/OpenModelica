// name:     Subscript3
// keywords: subscript array prefix
// status:   correct
//
// Checks that subscripts are correctly prefixed.
//

package A
  constant Integer i[2] = {0, 1};
end A;

model B
  Integer a;
  Integer r[2];
equation
  r[1] = r[a];
  r[2] = A.i[a];
end B;

model Subscript3
  B b;
end Subscript3;

// Result:
// class Subscript3
//   Integer b.a;
//   Integer b.r[1];
//   Integer b.r[2];
// equation
//   b.r[1] = b.r[b.a];
//   b.r[2] = {0, 1}[b.a];
// end Subscript3;
// endResult
