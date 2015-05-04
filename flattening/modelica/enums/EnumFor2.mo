// name:     EnumFor2
// keywords: enumeration enum range for loop
// status:   correct
//
// Tests that enumeration literals are preserved when used in for loops.
//

type E = enumeration(a, b, c, d, e, f);

model M
  Real e[E];
end M;

model EnumFor2
  M c1, c2;
equation
  for i in E loop
    c1.e[i] = c2.e[i];
  end for;
end EnumFor2;

// Result:
// class EnumFor2
//   Real c1.e[E.a];
//   Real c1.e[E.b];
//   Real c1.e[E.c];
//   Real c1.e[E.d];
//   Real c1.e[E.e];
//   Real c1.e[E.f];
//   Real c2.e[E.a];
//   Real c2.e[E.b];
//   Real c2.e[E.c];
//   Real c2.e[E.d];
//   Real c2.e[E.e];
//   Real c2.e[E.f];
// equation
//   c1.e[E.a] = c2.e[E.a];
//   c1.e[E.b] = c2.e[E.b];
//   c1.e[E.c] = c2.e[E.c];
//   c1.e[E.d] = c2.e[E.d];
//   c1.e[E.e] = c2.e[E.e];
//   c1.e[E.f] = c2.e[E.f];
// end EnumFor2;
// endResult
