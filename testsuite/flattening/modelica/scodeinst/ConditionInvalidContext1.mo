// name: ConditionInvalidContext1
// keywords:
// status: incorrect
//

model ConditionInvalidContext1
  Real x if false;
equation
  x = 1;
end ConditionInvalidContext1;

// Result:
// Error processing file: ConditionInvalidContext1.mo
// [flattening/modelica/scodeinst/ConditionInvalidContext1.mo:9:3-9:8:writable] Error: 'x' refers to a component with a false condition.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
