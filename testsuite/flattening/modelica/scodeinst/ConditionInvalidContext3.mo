// name: ConditionInvalidContext3
// keywords:
// status: incorrect
//

model A
  Real x;
end A;

model ConditionInvalidContext3
  A a[3] if false;
algorithm
  a[1].x := 1;
end ConditionInvalidContext3;

// Result:
// Error processing file: ConditionInvalidContext3.mo
// [flattening/modelica/scodeinst/ConditionInvalidContext3.mo:13:3-13:14:writable] Error: 'a[1].x' refers to a component with a false condition.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
