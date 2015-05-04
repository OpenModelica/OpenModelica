// name:     DisturbedResistance1
// keywords: modification
// status:   incorrect
//
// A parameter must not be time-varying.
//

model Resistor
  Real u, i;
  parameter Real R = 1.0;
equation
  u = R*i;
end Resistor;

model DisturbedResistance1
  extends Resistor(R = 1.0 + 0.1*sin(time));
end DisturbedResistance1;
// Result:
// Error processing file: DisturbedResistance1.mo
// [flattening/modelica/modification/DisturbedResistance1.mo:16:20-16:43:writable] Error: Component R of variability PARAM has binding 1.0 + 0.1 * sin(time) of higher variability VAR.
// Error: Error occurred while flattening model DisturbedResistance1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
