// name: ConditionInvalidType1
// keywords:
// status: incorrect
//

model ConditionInvalidType1
  Real x if "true";
end ConditionInvalidType1;

// Result:
// Error processing file: ConditionInvalidType1.mo
// [flattening/modelica/scodeinst/ConditionInvalidType1.mo:7:3-7:19:writable] Error: Type error in conditional '"true"'. Expected Boolean, got String.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
