// name: Identity1
// keywords: identity
// status: correct
//
// Tests the built in operator identity.
//

model Identity1
  Integer a1[2, 2] = identity(2);
  parameter Integer n = 3;
  Integer a2[n, n] = identity(n);
  Integer m = 3;
  Integer a3[3, 3] = identity(m);
end Identity1;

// Result:
// class Identity1
//   Integer a1[1,1];
//   Integer a1[1,2];
//   Integer a1[2,1];
//   Integer a1[2,2];
//   parameter Integer n = 3;
//   Integer a2[1,1];
//   Integer a2[1,2];
//   Integer a2[1,3];
//   Integer a2[2,1];
//   Integer a2[2,2];
//   Integer a2[2,3];
//   Integer a2[3,1];
//   Integer a2[3,2];
//   Integer a2[3,3];
//   Integer m = 3;
//   Integer a3[1,1];
//   Integer a3[1,2];
//   Integer a3[1,3];
//   Integer a3[2,1];
//   Integer a3[2,2];
//   Integer a3[2,3];
//   Integer a3[3,1];
//   Integer a3[3,2];
//   Integer a3[3,3];
// equation
//   a1 = {{1, 0}, {0, 1}};
//   a2 = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
//   a3 = identity(m);
// end Identity1;
// endResult
