// name:     SpatialDistribution3
// keywords: builtin
// status:   correct
//
// Test builtin function spatialDistribution.
//

model SpatialDistribution3
  Real x;
  Real v = 1;
  Real in0 = time;
  Real out1;
equation
  der(x) = v;
  (, out1) = spatialDistribution(in0, 1.0, x, true, {0.0, 1.0}, {0.0, 0.0});
end SpatialDistribution3;

// Result:
// class SpatialDistribution3
//   Real x;
//   Real v = 1.0;
//   Real in0 = time;
//   Real out1;
// equation
//   der(x) = v;
//   (_, out1) = spatialDistribution(in0, 1.0, x, true, {0.0, 1.0}, {0.0, 0.0});
// end SpatialDistribution3;
// endResult
