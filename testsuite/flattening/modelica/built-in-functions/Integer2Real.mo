// name:     Integer2Real
// keywords: type
// status:   correct
//
// Automatic conversion from Integer to Real.
//

class Integer2Real
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
//   a = 0.5 * /*Real*/(n);
// end Integer2Real;
// endResult
