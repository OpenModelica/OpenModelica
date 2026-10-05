// name:     SpatialDistribution5
// keywords: builtin
// status:   incorrect
//
// Test builtin function spatialDistribution.
//

model SpatialDistribution5
  Real x;
  Real v = 1;
  Real in0 = time;
  Real out0;
  Real out1;
equation
  der(x) = v;
  (out0, ) = spatialDistribution(in0, 0.0, x, true, {0.0, 1.0}, {0.0, 0.0});
end SpatialDistribution5;

// Result:
// Error processing file: SpatialDistribution5.mo
// [flattening/modelica/built-in-functions/SpatialDistribution5.mo:16:3-16:76:writable] Error: The second output of spatialDistribution may not be ignored.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
