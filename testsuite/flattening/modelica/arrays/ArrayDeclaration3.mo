// name: ArrayDeclaration3
// keywords: array
// status: correct
//
// Tests declaring arrays and scalars on the same line
//

model ArrayDeclaration3
  Real a,b[2];
  Real c[2],d;
equation
  a = 1;
  b[1] = 2;
  b[2] = 3;
  c[1] = 4;
  c[2] = 5;
  d = 6;
end ArrayDeclaration3;

// Result:
// class ArrayDeclaration3
//   Real a;
//   Real b[1];
//   Real b[2];
//   Real c[1];
//   Real c[2];
//   Real d;
// equation
//   a = 1.0;
//   b[1] = 2.0;
//   b[2] = 3.0;
//   c[1] = 4.0;
//   c[2] = 5.0;
//   d = 6.0;
// end ArrayDeclaration3;
// endResult
