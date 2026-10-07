// name:     VectorBuiltin
// keywords: array
// status:   correct
//
// Test elaboration of the builtin vector function.

model VectorBuiltin
  output Real A[1];
  output Real B[4];
  output Real C[4];
  output Real D[4];
equation
  A = vector({1});
  B = vector({1,2,3,4});
  C = vector({{1},{2},{3},{4}});
  D = vector({{{1}},{{2}},{{3}},{{4}}});
end VectorBuiltin;

// Result:
// class VectorBuiltin
//   output Real A[1];
//   output Real B[1];
//   output Real B[2];
//   output Real B[3];
//   output Real B[4];
//   output Real C[1];
//   output Real C[2];
//   output Real C[3];
//   output Real C[4];
//   output Real D[1];
//   output Real D[2];
//   output Real D[3];
//   output Real D[4];
// equation
//   A[1] = 1.0;
//   B[1] = 1.0;
//   B[2] = 2.0;
//   B[3] = 3.0;
//   B[4] = 4.0;
//   C[1] = 1.0;
//   C[2] = 2.0;
//   C[3] = 3.0;
//   C[4] = 4.0;
//   D[1] = 1.0;
//   D[2] = 2.0;
//   D[3] = 3.0;
//   D[4] = 4.0;
// end VectorBuiltin;
// endResult
