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
//   Real A[EnumFor.E.a];
//   Real A[EnumFor.E.b];
//   Real A[EnumFor.E.c];
//   Real A[EnumFor.E.d];
//   Real A[EnumFor.E.e];
//   Real A[EnumFor.E.f];
//   Real B[EnumFor.E.a];
//   Real B[EnumFor.E.b];
//   Real B[EnumFor.E.c];
//   Real B[EnumFor.E.d];
//   Real B[EnumFor.E.e];
//   Real B[EnumFor.E.f];
//   Real C[EnumFor.E.a];
//   Real C[EnumFor.E.b];
//   Real C[EnumFor.E.c];
//   Real C[EnumFor.E.d];
//   Real C[EnumFor.E.e];
//   Real C[EnumFor.E.f];
// equation
//   B[EnumFor.E.a] = A[EnumFor.E.a];
//   B[EnumFor.E.b] = A[EnumFor.E.b];
//   B[EnumFor.E.c] = A[EnumFor.E.c];
//   B[EnumFor.E.d] = A[EnumFor.E.d];
//   B[EnumFor.E.e] = A[EnumFor.E.e];
//   B[EnumFor.E.f] = A[EnumFor.E.f];
//   C[EnumFor.E.c] = B[EnumFor.E.c];
//   C[EnumFor.E.d] = B[EnumFor.E.d];
//   C[EnumFor.E.e] = B[EnumFor.E.e];
// end EnumFor;
// endResult
