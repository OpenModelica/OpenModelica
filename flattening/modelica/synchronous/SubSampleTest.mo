// name: SubSampleTest
// keywords: synchronous features
// status: correct

model SubSampleTest
  output Integer x[2];
  output Real y;
  Integer z[2];
equation
  y = subSample(2.1);
  x = subSample(z, 2);
end SubSampleTest;

// Result:
// class SubSampleTest
//   output Integer x[1];
//   output Integer x[2];
//   output Real y;
//   Integer z[1];
//   Integer z[2];
// equation
//   y = subSample(2.1, 0);
//   x[1] = subSample(z[1], 2);
//   x[2] = subSample(z[2], 2);
// end SubSampleTest;
// endResult
