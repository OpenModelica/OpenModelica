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
//   Real X[EnumDimSum.E.one];
//   Real X[EnumDimSum.E.two];
//   Real X[EnumDimSum.E.three];
//   Real x;
//   Real y;
// equation
//   x = X[EnumDimSum.E.one] + X[EnumDimSum.E.two] + X[EnumDimSum.E.three];
//   y = X[EnumDimSum.E.one] ^ 2.0 + X[EnumDimSum.E.two] ^ 2.0 + X[EnumDimSum.E.three] ^ 2.0;
// end EnumDimSum;
// endResult
