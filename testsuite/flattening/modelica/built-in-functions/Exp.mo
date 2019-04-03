// name: Exp
// keywords: exp
// status: correct
//
// Tests the built-in exp function
//

model Exp
  Real r;
equation
  r = exp(45);
end Exp;

// Result:
// class Exp
//   Real r;
// equation
//   r = 3.4934271057485095e+19;
// end Exp;
// endResult
