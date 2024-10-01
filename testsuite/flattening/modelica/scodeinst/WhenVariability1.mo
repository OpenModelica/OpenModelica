// name: WhenVariablity1
// keywords:
// status: incorrect
//

model WhenVariability1
  Real x;
equation
  when pre(x) > 1 then
  end when;
end WhenVariability1;

// Result:
// Error processing file: WhenVariability1.mo
// [flattening/modelica/scodeinst/WhenVariability1.mo:9:3-10:11:writable] Error: Argument 1 of pre must be a discrete expression, but x is continuous.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
