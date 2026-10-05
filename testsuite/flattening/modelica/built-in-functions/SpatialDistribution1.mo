// name:     SpatialDistribution1
// keywords: builtin
// status:   correct
//
// Test builtin function spatialDistribution.
//

model SpatialDistribution1
  Real x;
  Real v = 1;
  Real in0 = time;
  Real out0;
  Real out1;
equation
  der(x) = v;
  (out0, out1) = spatialDistribution(in0, 0.0, x, true, {0.0, 1.0}, {0.0, 0.0});
end SpatialDistribution1;

// Result:
// class SpatialDistribution1
//   Real x;
//   Real v = 1.0;
//   Real in0 = time;
//   Real out0;
//   Real out1;
// equation
//   der(x) = v;
//   (out0, out1) = spatialDistribution(in0, 0.0, x, true, {0.0, 1.0}, {0.0, 0.0});
// end SpatialDistribution1;
// endResult
