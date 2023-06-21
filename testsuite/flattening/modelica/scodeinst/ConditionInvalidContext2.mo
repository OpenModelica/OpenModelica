// name: ConditionInvalidContext2
// keywords:
// status: incorrect
// cflags: -d=newInst --strict
//

model ConditionInvalidContext2
  Real x if true;
  Real y = x;
end ConditionInvalidContext2;


// Result:
// Error processing file: ConditionInvalidContext2.mo
// [flattening/modelica/scodeinst/ConditionInvalidContext2.mo:9:3-9:13:writable] Error: Conditional component 'x' is used in a non-connect context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
