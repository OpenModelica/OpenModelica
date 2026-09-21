// name:     SpatialDistribution4
// keywords: builtin
// status:   incorrect
//
// Test builtin function spatialDistribution.
//

model SpatialDistribution4
  Real x;
  Real v = 1;
  Real in0 = time;
  Real out0;
  Real out1;
equation
  der(x) = v;
  (, out1) = spatialDistribution(in0, 0.0, x, false, {0.0, 1.0}, {0.0, 0.0});
end SpatialDistribution4;

// Result:
// Error processing file: SpatialDistribution4.mo
// [flattening/modelica/built-in-functions/SpatialDistribution4.mo:16:3-16:77:writable] Error: The first output of spatialDistribution may only be ignored if positiveVelocity is true.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
