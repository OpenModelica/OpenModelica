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
//   z = /*Real[2]*/(superSample({1, 2}, 0));
//   y = superSample({z[1], z[2]}, 2);
// end SuperSampleTest;
// endResult
