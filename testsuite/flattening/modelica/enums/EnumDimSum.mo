// name: EnumDimSum
// keywords: enum dimension sum
// status: correct
//
// Checks that sum of an array whose dimension is an enumeration is expanded
// correctly.
//

model EnumDimSum
  type E = enumeration(one, two, three);
  Real X[E];
  Real x, y;
equation
  x = sum(X);
  y = sum(X[i]^2 for i in E);
end EnumDimSum;

// Result:
// class EnumDimSum
//   Real X[E.one];
//   Real X[E.two];
//   Real X[E.three];
//   Real x;
//   Real y;
// equation
//   x = X[E.one] + X[E.two] + X[E.three];
//   y = X[E.one] ^ 2.0 + X[E.two] ^ 2.0 + X[E.three] ^ 2.0;
// end EnumDimSum;
// endResult
