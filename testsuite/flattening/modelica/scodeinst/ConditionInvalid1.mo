// name: ConditionInvalid1
// keywords:
// status: incorrect
//

model ConditionInvalid1
  parameter Boolean b(fixed = false);
  Real x if b;
end ConditionInvalid1;

// Result:
// Error processing file: ConditionInvalid1.mo
// [flattening/modelica/scodeinst/ConditionInvalid1.mo:8:3-8:14:writable] Error: The conditional expression b could not be evaluated.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
