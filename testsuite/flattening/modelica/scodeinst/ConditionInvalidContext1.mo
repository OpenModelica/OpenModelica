// name: ConditionInvalidContext1
// keywords:
// status: incorrect
//

model ConditionInvalidContext1
  Real x if true;
equation
  x = 1;
  annotation(__OpenModelica_commandLineOptions="--strict");
end ConditionInvalidContext1;


// Result:
// Error processing file: ConditionInvalidContext1.mo
// [flattening/modelica/scodeinst/ConditionInvalidContext1.mo:9:3-9:8:writable] Error: Conditional component 'x' is used in a non-connect context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
