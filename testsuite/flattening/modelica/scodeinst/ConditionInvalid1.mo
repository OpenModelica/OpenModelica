// name: ConditionInvalid1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ConditionInvalid1
  parameter Boolean b;
  Real x if b;
end ConditionInvalid1;

// Result:
// Error processing file: ConditionInvalid1.mo
// [flattening/modelica/scodeinst/ConditionInvalid1.mo:9:3-9:14:writable] Error: The conditional expression b could not be evaluated.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
