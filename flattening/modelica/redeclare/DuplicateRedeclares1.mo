// name:     DuplicateRedeclares1
// keywords: redeclare
// status:   incorrect
//
// Checks that the compiler issues an error on duplicate redeclares.
//

model M
  replaceable Real r;
end M;

model DuplicateRedeclares1
  extends M(redeclare replaceable Real r = 1.5);

  redeclare replaceable Real r = 2.5;
end DuplicateRedeclares1;

// Result:
// Error processing file: DuplicateRedeclares1.mo
// [flattening/modelica/redeclare/DuplicateRedeclares1.mo:13:23-13:47:writable] Notification: From here:
// [flattening/modelica/redeclare/DuplicateRedeclares1.mo:15:3-15:37:writable] Error: r is already redeclared in this scope.
// Error: Error occurred while flattening model DuplicateRedeclares1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
