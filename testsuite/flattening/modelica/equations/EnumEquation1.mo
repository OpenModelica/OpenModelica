// name:     EnumEquation1
// keywords: equation, enumeration
// status:   correct
//
// Checks that equations involving enumeration work.
//

model EnumEquation1
  type E = enumeration(a, b, c);
  E e1, e2;
equation
  e1 = E.a;
  E.b = e2;
  E.a = E.a;
end EnumEquation1;

// Result:
// class EnumEquation1
//   enumeration(a, b, c) e1;
//   enumeration(a, b, c) e2;
// equation
//   e1 = EnumEquation1.E.a;
//   e2 = EnumEquation1.E.b;
//   EnumEquation1.E.a = EnumEquation1.E.a;
// end EnumEquation1;
// endResult
