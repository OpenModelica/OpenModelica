// name:     SpatialDistribution2
// keywords: builtin
// status:   incorrect
//
// Test builtin function spatialDistribution.
//

model SpatialDistribution2
  Real x;
  Real v = 1;
  Real in0 = time;
  Real out0;
  Real out1;
equation
  der(x) = v;
  out0 = out1 + spatialDistribution(in0, 0.0, x, true, {0.0, 1.0}, {0.0, 0.0});
end SpatialDistribution2;

// Result:
// Error processing file: SpatialDistribution2.mo
// [flattening/modelica/built-in-functions/SpatialDistribution2.mo:16:3-16:79:writable] Error: spatialDistribution may only be used as the right hand side of an equation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
