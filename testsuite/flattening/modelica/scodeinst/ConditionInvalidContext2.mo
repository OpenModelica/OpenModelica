// name: ConditionInvalidContext2
// keywords:
// status: incorrect
//

model A
  Real x;
end A;

model ConditionInvalidContext2
  A a if false;
equation
  a.x = 1;
end ConditionInvalidContext2;

// Result:
// Error processing file: ConditionInvalidContext2.mo
// [flattening/modelica/scodeinst/ConditionInvalidContext2.mo:13:3-13:10:writable] Error: 'a.x' refers to a component with a false condition.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
