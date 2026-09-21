// name:     SpatialDistribution7
// keywords: builtin
// status:   incorrect
//
// Test builtin function spatialDistribution.
//

model SpatialDistribution7
  Real x;
  Real v = 1;
  Real in0 = time;
  Real out0;
  Real out1;
equation
  der(x) = v;
  (, out1) = noEvent(spatialDistribution(in0, 0.0, x, false, {0.0, 1.0}, {0.0, 0.0}));
end SpatialDistribution7;

// Result:
// Error processing file: SpatialDistribution7.mo
// [flattening/modelica/built-in-functions/SpatialDistribution7.mo:16:3-16:86:writable] Error: The first output of spatialDistribution may only be ignored if positiveVelocity is true.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
