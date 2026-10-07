// name:     FinalRedeclareModifier
// keywords: redeclare, modification, final
// status:   incorrect
//
// Checks that it's not allowed to redeclare a component declared as final.
//

model m
  final replaceable Real x;
end m;

model FinalRedeclareModifier
  extends m(replaceable Real x = 2.0);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end FinalRedeclareModifier;

// Result:
// Error processing file: FinalRedeclareModifier.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/redeclare/FinalRedeclareModifier.mo:13:3-13:38:writable] Notification: From here:
// [flattening/modelica/redeclare/FinalRedeclareModifier.mo:9:3-9:27:writable] Error: Redeclaration of final component x is not allowed.
// Error: Error occurred while flattening model FinalRedeclareModifier
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
