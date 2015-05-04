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
end FinalRedeclareModifier;

// Result:
// Error processing file: FinalRedeclareModifier.mo
// [flattening/modelica/redeclare/FinalRedeclareModifier.mo:13:3-13:38:writable] Notification: From here:
// [flattening/modelica/redeclare/FinalRedeclareModifier.mo:9:3-9:27:writable] Error: Redeclaration of final component x is not allowed.
// Error: Error occurred while flattening model FinalRedeclareModifier
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
