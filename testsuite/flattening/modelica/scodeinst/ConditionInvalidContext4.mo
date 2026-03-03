// name: ConditionInvalidContext4
// keywords:
// status: incorrect
//

model ConditionInvalidContext4
  Real x if false;
  Real y = x;
end ConditionInvalidContext4;

// Result:
// Error processing file: ConditionInvalidContext4.mo
// [flattening/modelica/scodeinst/ConditionInvalidContext4.mo:8:3-8:13:writable] Error: 'x' refers to a component with a false condition.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
