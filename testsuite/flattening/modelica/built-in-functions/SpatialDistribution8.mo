// name:     SpatialDistribution8
// keywords: builtin
// status:   incorrect
//
// Test builtin function spatialDistribution.
//

model SpatialDistribution8
  Real x;
  Real v = 1;
  Real in0 = time;
  Real out1;
  parameter Boolean b = true;
equation
  der(x) = v;

  if b then
    (, out1) = noEvent(spatialDistribution(in0, 0.0, x, false, {0.0, 1.0}, {0.0, 0.0}));
  else
    out1 = 0;
  end if;
end SpatialDistribution8;

// Result:
// Error processing file: SpatialDistribution8.mo
// [flattening/modelica/built-in-functions/SpatialDistribution8.mo:18:5-18:88:writable] Error: spatialDistribution is not allowed in an if-equation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
