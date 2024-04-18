// name:     RedeclareModifierInvalid2
// keywords: redeclare, modification, replaceable
// status:   incorrect
// cflags: -d=-newInst
//
// Checks that the redeclared class needs to be replaceable.
//

model m
  model m2 end m2;
end m;

model RedeclareModifierInvalid2
  model m3 end m3;
  extends m(redeclare model m2 = m3);
end RedeclareModifierInvalid2;

// Result:
// Error processing file: RedeclareModifierInvalid2.mo
// [flattening/modelica/redeclare/RedeclareModifierInvalid2.mo:15:3-15:37:writable] Notification: From here:
// [flattening/modelica/redeclare/RedeclareModifierInvalid2.mo:10:3-10:18:writable] Error: Redeclaration with a new type requires 'm2' to be replaceable.
// Error: Error occurred while flattening model RedeclareModifierInvalid2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
