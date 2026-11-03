// name:     Overwriting1
// keywords: modification,equation
// status:   correct
//
// The modification does not overwrite the equation

model A
  Real x, u;
equation
  x = 2.0 * u;
end A;

model Overwriting1 = A(x = 5.0);

// Result:
// class Overwriting1
//   Real x = 5.0;
//   Real u;
// equation
//   x = 2.0 * u;
// end Overwriting1;
// endResult
