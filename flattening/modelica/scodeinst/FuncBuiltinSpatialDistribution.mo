// name: FuncBuiltinSpatialDistribution
// keywords: spacialDistribution
// status: correct
// cflags: -d=newInst
//
// Tests the builtin spacialDistribution operator.
//

model FuncBuiltinSpatialDistribution
  Real in0;
  Real in1;
  Real out0;
  Real out1;
  Real x;
  Boolean positiveVelocity;
equation
  (out0, out1) = spatialDistribution(in0, in1, x, positiveVelocity,
    initialPoints = {0.0, 1.0}, initialValues = {0.0, 0.0});
end FuncBuiltinSpatialDistribution;

// Result:
// class FuncBuiltinSpatialDistribution
//   Real in0;
//   Real in1;
//   Real out0;
//   Real out1;
//   Real x;
//   Boolean positiveVelocity;
// equation
//   (out0, out1) = spatialDistribution(in0, in1, x, positiveVelocity, {0.0, 1.0}, {0.0, 0.0});
// end FuncBuiltinSpatialDistribution;
// endResult
