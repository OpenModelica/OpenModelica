// name: ConditionInvalidContext2
// keywords:
// status: incorrect
//

model ConditionInvalidContext2
  Real x if true;
  Real y = x;
  annotation(__OpenModelica_commandLineOptions="--strict");
end ConditionInvalidContext2;


// Result:
// Error processing file: ConditionInvalidContext2.mo
// [flattening/modelica/scodeinst/ConditionInvalidContext2.mo:8:3-8:13:writable] Error: Conditional component 'x' is used in a non-connect context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
