// name: ShiftSampleTest
// keywords: synchronous features
// status: correct

model ShiftSampleTest
  output Real x;
  output Real y[2];
  Real z[2];
equation
  x = shiftSample(1.0, 2, 4);
  y = shiftSample(z, 3);
end ShiftSampleTest;

// Result:
// class ShiftSampleTest
//   output Real x;
//   output Real y[1];
//   output Real y[2];
//   Real z[1];
//   Real z[2];
// equation
//   x = shiftSample(1.0, 2, 4);
//   y[1] = shiftSample(z[1], 3, 1);
//   y[2] = shiftSample(z[2], 3, 1);
// end ShiftSampleTest;
// endResult
