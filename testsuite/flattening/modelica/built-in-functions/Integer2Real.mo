// name:     Integer2Real
// keywords: type
// status:   correct
//
// Automatic conversion from Integer to Real.
//

model Integer2Real
  Integer n;
  Real a;
equation
  n = 5;
  a = n / 2;
end Integer2Real;

// Result:
// class Integer2Real
//   Integer n;
//   Real a;
// equation
//   n = 5;
//   a = /*Real*/(n) / 2.0;
// end Integer2Real;
// endResult
