// name:     EnumRange
// keywords: enumeration enum range reduction
// status:   correct
//
// Tests that enumeration literals are preserved when used in ranges.
//

package Package1
  package Package2
    type E = enumeration(one, two, three);
  end Package2;
end Package1;

model Test
  type E3 = enumeration(x, y, z);
end Test;

model EnumRange
  type E2 = enumeration(a, b, c, d, e, f);

  Real A[Package1.Package2.E];
  Real B[E2];
  Real C[Test.E3];
  Real a, b, c;
equation
  a = sum(A[i] for i in Package1.Package2.E.one : Package1.Package2.E.two);
  b = sum(B[i] for i in E2.b : E2.e);
  c = sum(C[i] for i in Test.E3.x : Test.E3.z);
end EnumRange;

// Result:
// class EnumRange
//   Real A[Package1.Package2.E.one];
//   Real A[Package1.Package2.E.two];
//   Real A[Package1.Package2.E.three];
//   Real B[EnumRange.E2.a];
//   Real B[EnumRange.E2.b];
//   Real B[EnumRange.E2.c];
//   Real B[EnumRange.E2.d];
//   Real B[EnumRange.E2.e];
//   Real B[EnumRange.E2.f];
//   Real C[Test.E3.x];
//   Real C[Test.E3.y];
//   Real C[Test.E3.z];
//   Real a;
//   Real b;
//   Real c;
// equation
//   a = A[Package1.Package2.E.one] + A[Package1.Package2.E.two];
//   b = B[EnumRange.E2.b] + B[EnumRange.E2.c] + B[EnumRange.E2.d] + B[EnumRange.E2.e];
//   c = C[Test.E3.x] + C[Test.E3.y] + C[Test.E3.z];
// end EnumRange;
// endResult
