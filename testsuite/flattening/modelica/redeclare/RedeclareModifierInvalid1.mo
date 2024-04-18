// name:     RedeclareModifierInvalid1
// keywords: redeclare, modification, replaceable
// status:   incorrect
// cflags: -d=-newInst
//
// Checks that the redeclared component needs to be replaceable if the type is
// changed.
//

model m
  Real x;
end m;

model RedeclareModifierInvalid1
  type MyReal = Real;
  extends m(replaceable MyReal x = 2.0);
end RedeclareModifierInvalid1;

// Result:
// Error processing file: RedeclareModifierInvalid1.mo
// [flattening/modelica/redeclare/RedeclareModifierInvalid1.mo:16:3-16:40:writable] Notification: From here:
// [flattening/modelica/redeclare/RedeclareModifierInvalid1.mo:11:3-11:9:writable] Error: Redeclaration with a new type requires 'x' to be replaceable.
// Error: Error occurred while flattening model RedeclareModifierInvalid1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
