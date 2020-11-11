// name:     FinalRedeclareModifier
// keywords: redeclare, modification, final
// status:   incorrect
// cflags: -d=-newInst
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
// [flattening/modelica/redeclare/FinalRedeclareModifier.mo:14:3-14:38:writable] Notification: From here:
// [flattening/modelica/redeclare/FinalRedeclareModifier.mo:10:3-10:27:writable] Error: Redeclaration of final component x is not allowed.
// Error: Error occurred while flattening model FinalRedeclareModifier
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
