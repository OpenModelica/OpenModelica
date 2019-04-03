// name:     DisturbedResistance3
// keywords: modification
// status:   incorrect
//
// This is an example of replacing a variable without using
// redeclaration syntax.
//
// This was made illegal in Modelica 1.4 since it depends
// very much on declaration order.
//

model Resistor
  Real u, i;
  parameter Real R = 1.0;
equation
  u = R*i;
end Resistor;

model DisturbedResistance3
  Real R = 1.0 + 0.1*sin(time);
  extends Resistor;
end DisturbedResistance3;

// Result:
// Error processing file: DisturbedResistance3.mo
// [flattening/modelica/modification/DisturbedResistance3.mo:20:3-20:31:writable] Notification: From here:
// [flattening/modelica/modification/DisturbedResistance3.mo:14:3-14:25:writable] Error: Duplicate elements (due to inherited elements) not identical:
//   first element is:  Real R = 1.0 + 0.1 * sin(time)
//   second element is: parameter .Real R = 1.0
// Error: Error occurred while flattening model DisturbedResistance3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
