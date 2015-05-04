// name: SuperSampleTest
// keywords: synchronous features
// status: correct

model SuperSampleTest
  output Real x;
  output Real y[2];
  Real z[2];
equation
  x = superSample(1.0);
  z = superSample({1,2});
  y = superSample(z, 2);
end SuperSampleTest;

// Result:
// class SuperSampleTest
//   output Real x;
//   output Real y[1];
//   output Real y[2];
//   Real z[1];
//   Real z[2];
// equation
//   x = superSample(1.0, 0);
//   z[1] = /*Real*/(superSample(1, 0));
//   z[2] = /*Real*/(superSample(2, 0));
//   y[1] = superSample(z[1], 2);
//   y[2] = superSample(z[2], 2);
// end SuperSampleTest;
// endResult
