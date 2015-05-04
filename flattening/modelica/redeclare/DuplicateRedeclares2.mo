// name:     DuplicateRedeclares2
// keywords: redeclare
// status:   incorrect
//
// Checks that the compiler issues an error on duplicate redeclares.
//

model M
  replaceable Real r;
end M;

model DuplicateRedeclares2
  extends N(redeclare replaceable Real r = 1.5,
            redeclare replaceable Real r = 2.0);
end DuplicateRedeclares2;

// Result:
// Error processing file: DuplicateRedeclares2.mo
// [flattening/modelica/redeclare/DuplicateRedeclares2.mo:13:23-13:47:writable] Notification: From here:
// [flattening/modelica/redeclare/DuplicateRedeclares2.mo:14:23-14:47:writable] Error: r is already redeclared in this scope.
// Error: Error occurred while flattening model DuplicateRedeclares2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
