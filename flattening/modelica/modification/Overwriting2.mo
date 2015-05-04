// name:     Overwriting2
// keywords: modification,equation
// status:   correct
//
// The modification for `x' does not overwrite the equation.

class Overwriting2
  Real x = 5.0+u;
  Real u;
equation
  x = 2.0;
end Overwriting2;

// Result:
// class Overwriting2
//   Real x = 5.0 + u;
//   Real u;
// equation
//   x = 2.0;
// end Overwriting2;
// endResult
