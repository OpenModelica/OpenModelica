// name:     EnumMatrixProduct
// keywords: enum matrix product
// status:   correct
//
// Tests that enumeration literals are preserved when doing matrix/vector
// multiplications.
//

type E = enumeration (AA, BB, CC);

model EnumMatrixProduct
  Real[E] e1;
  Real[E, E] e2;
  Real[E] e3;
  Real[E, E] e4;
equation
  e3 = e1 * e2;
  e4 = e2 * e2;
end EnumMatrixProduct;

// Result:
// class EnumMatrixProduct
//   Real e1[E.AA];
//   Real e1[E.BB];
//   Real e1[E.CC];
//   Real e2[E.AA,E.AA];
//   Real e2[E.AA,E.BB];
//   Real e2[E.AA,E.CC];
//   Real e2[E.BB,E.AA];
//   Real e2[E.BB,E.BB];
//   Real e2[E.BB,E.CC];
//   Real e2[E.CC,E.AA];
//   Real e2[E.CC,E.BB];
//   Real e2[E.CC,E.CC];
//   Real e3[E.AA];
//   Real e3[E.BB];
//   Real e3[E.CC];
//   Real e4[E.AA,E.AA];
//   Real e4[E.AA,E.BB];
//   Real e4[E.AA,E.CC];
//   Real e4[E.BB,E.AA];
//   Real e4[E.BB,E.BB];
//   Real e4[E.BB,E.CC];
//   Real e4[E.CC,E.AA];
//   Real e4[E.CC,E.BB];
//   Real e4[E.CC,E.CC];
// equation
//   e3[E.AA] = e1[E.AA] * e2[E.AA,E.AA] + e1[E.BB] * e2[E.BB,E.AA] + e1[E.CC] * e2[E.CC,E.AA];
//   e3[E.BB] = e1[E.AA] * e2[E.AA,E.BB] + e1[E.BB] * e2[E.BB,E.BB] + e1[E.CC] * e2[E.CC,E.BB];
//   e3[E.CC] = e1[E.AA] * e2[E.AA,E.CC] + e1[E.BB] * e2[E.BB,E.CC] + e1[E.CC] * e2[E.CC,E.CC];
//   e4[E.AA,E.AA] = e2[E.AA,E.AA] ^ 2.0 + e2[E.AA,E.BB] * e2[E.BB,E.AA] + e2[E.AA,E.CC] * e2[E.CC,E.AA];
//   e4[E.AA,E.BB] = e2[E.AA,E.BB] * (e2[E.AA,E.AA] + e2[E.BB,E.BB]) + e2[E.AA,E.CC] * e2[E.CC,E.BB];
//   e4[E.AA,E.CC] = e2[E.AA,E.AA] * e2[E.AA,E.CC] + e2[E.AA,E.BB] * e2[E.BB,E.CC] + e2[E.AA,E.CC] * e2[E.CC,E.CC];
//   e4[E.BB,E.AA] = e2[E.BB,E.AA] * (e2[E.AA,E.AA] + e2[E.BB,E.BB]) + e2[E.BB,E.CC] * e2[E.CC,E.AA];
//   e4[E.BB,E.BB] = e2[E.BB,E.AA] * e2[E.AA,E.BB] + e2[E.BB,E.BB] ^ 2.0 + e2[E.BB,E.CC] * e2[E.CC,E.BB];
//   e4[E.BB,E.CC] = e2[E.BB,E.AA] * e2[E.AA,E.CC] + e2[E.BB,E.BB] * e2[E.BB,E.CC] + e2[E.BB,E.CC] * e2[E.CC,E.CC];
//   e4[E.CC,E.AA] = e2[E.CC,E.AA] * e2[E.AA,E.AA] + e2[E.CC,E.BB] * e2[E.BB,E.AA] + e2[E.CC,E.CC] * e2[E.CC,E.AA];
//   e4[E.CC,E.BB] = e2[E.CC,E.AA] * e2[E.AA,E.BB] + e2[E.CC,E.BB] * e2[E.BB,E.BB] + e2[E.CC,E.CC] * e2[E.CC,E.BB];
//   e4[E.CC,E.CC] = e2[E.CC,E.AA] * e2[E.AA,E.CC] + e2[E.CC,E.BB] * e2[E.BB,E.CC] + e2[E.CC,E.CC] ^ 2.0;
// end EnumMatrixProduct;
// endResult
