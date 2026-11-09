// name:     EnumFor
// keywords: enumeration enum range for loop
// status:   correct
//
// Tests that enumeration literals are preserved when used in for loops.
//

model EnumFor
  type E = enumeration(a, b, c, d, e, f);

  Real A[E];
  Real B[E];
  Real C[E];
equation
  for i in E loop
    B[i] = A[i];
  end for;

  for i in E.c : E.e loop
    C[i] = B[i];
  end for;
end EnumFor;

// Result:
// class EnumFor
//   Real A[E.a];
//   Real A[E.b];
//   Real A[E.c];
//   Real A[E.d];
//   Real A[E.e];
//   Real A[E.f];
//   Real B[E.a];
//   Real B[E.b];
//   Real B[E.c];
//   Real B[E.d];
//   Real B[E.e];
//   Real B[E.f];
//   Real C[E.a];
//   Real C[E.b];
//   Real C[E.c];
//   Real C[E.d];
//   Real C[E.e];
//   Real C[E.f];
// equation
//   B[E.a] = A[E.a];
//   B[E.b] = A[E.b];
//   B[E.c] = A[E.c];
//   B[E.d] = A[E.d];
//   B[E.e] = A[E.e];
//   B[E.f] = A[E.f];
//   C[E.c] = B[E.c];
//   C[E.d] = B[E.d];
//   C[E.e] = B[E.e];
// end EnumFor;
// endResult
