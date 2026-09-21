// name:     SpatialDistribution9
// keywords: builtin
// status:   incorrect
//
// Test builtin function spatialDistribution.
//

model SpatialDistribution9
  Real x;
  Real v = 1;
  Real in0 = time;
  Real out1 = 0;
  parameter Boolean b = true;
equation
  der(x) = v;

  when time > 0.5 then
    (, out1) = noEvent(spatialDistribution(in0, 0.0, x, false, {0.0, 1.0}, {0.0, 0.0}));
  end when;
end SpatialDistribution9;

// Result:
// Error processing file: SpatialDistribution9.mo
// [flattening/modelica/built-in-functions/SpatialDistribution9.mo:18:5-18:88:writable] Error: spatialDistribution is not allowed in a when-equation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
