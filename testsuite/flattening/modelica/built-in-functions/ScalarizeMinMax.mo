// name:     ScalarizeMinMax
// keywords: scalarize min max
// status:   correct
// cflags:   +scalarizeMinMax
//
// Tests that min/max reductions are scalarized when +scalarizeMinMax is used.
//

model ScalarizeMinMax
  Real x[5];
  Real r1, r2;
equation
  r1 = min(x);
  r2 = max(x);
end ScalarizeMinMax;

// Result:
// class ScalarizeMinMax
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real r1;
//   Real r2;
// equation
//   r1 = min(x[1], min(x[2], min(x[3], min(x[4], x[5]))));
//   r2 = max(x[1], max(x[2], max(x[3], max(x[4], x[5]))));
// end ScalarizeMinMax;
// endResult
