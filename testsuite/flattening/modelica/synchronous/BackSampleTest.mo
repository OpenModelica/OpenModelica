// name: BackSampleTest
// keywords: synchronous features
// status: correct

model BackSampleTest
  output Real x;
  output Boolean y[2];
  Boolean z[2];
equation
  x = backSample(1.0, 2, 4);
  y = backSample(z, 3);
end BackSampleTest;

// Result:
// class BackSampleTest
//   output Real x;
//   output Boolean y[1];
//   output Boolean y[2];
//   Boolean z[1];
//   Boolean z[2];
// equation
//   x = backSample(1.0, 2, 4);
//   y[1] = backSample(z[1], 3, 1);
//   y[2] = backSample(z[2], 3, 1);
// end BackSampleTest;
// endResult
