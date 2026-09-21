// name: NonLiteralRange1
// keywords: range scalarization
// status: correct
//
// A range whose bounds are not literals is sized by the type it is matched
// against, so it can be scalarized.
//

model NonLiteralRange1
  parameter Integer n = 4;
  Real dx = time + 1.0;
  Real x0 = 8.0;
  Real x[n];
equation
  x = x0 + dx / 2 : dx : x0 + dx / 2 + dx * (n - 1);
end NonLiteralRange1;

// Result:
// class NonLiteralRange1
//   final parameter Integer n = 4;
//   Real dx = time + 1.0;
//   Real x0 = 8.0;
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
// equation
//   x[1] = x0 + dx / 2.0;
//   x[2] = x0 + dx / 2.0 + dx;
//   x[3] = x0 + dx / 2.0 + 2.0 * dx;
//   x[4] = x0 + dx / 2.0 + 3.0 * dx;
// end NonLiteralRange1;
// endResult
