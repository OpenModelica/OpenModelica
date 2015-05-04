// name:     Constant1
// keywords: declaration
// status:   correct
//
// Basic constant definitions.
//

class Constant1
  constant Real PI = 3.14159265358979;
  constant Integer N = 17;
  Real x;
equation
  x = 2.0 * PI;
end Constant1;

// Result:
// class Constant1
//   constant Real PI = 3.14159265358979;
//   constant Integer N = 17;
//   Real x;
// equation
//   x = 6.28318530717958;
// end Constant1;
// endResult
