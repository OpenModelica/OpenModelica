// name:     Non-expanded Array - Modification
// keywords: array
// status:   correct
// cflags:   +a
//
// Basic test of modification processing in the case of non-expanded arrays.
//

class A
  Real x;
end A;

class B
  A a(x=0);
end B;

model Modif1
  B[3] b;
end Modif1;

// Result:
// class Modif1
//   Real b[1:3].a.x = {0.0, 0.0, 0.0};
// equation
//   b[3].a.x = {0.0, 0.0, 0.0};
// end Modif1;
// endResult
