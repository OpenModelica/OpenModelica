// name: ConditionInvalidContext1
// keywords:
// status: incorrect
// cflags: -d=newInst --strict
//

model ConditionInvalidContext1
  Real x if true;
equation
  x = 1;
end ConditionInvalidContext1;


// Result:
// Error processing file: ConditionInvalidContext1.mo
// [flattening/modelica/scodeinst/ConditionInvalidContext1.mo:10:3-10:8:writable] Error: Conditional component 'x' is used in a non-connect context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
