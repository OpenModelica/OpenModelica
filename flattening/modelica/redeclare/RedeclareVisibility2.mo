// name:     RedeclareVisibility2
// keywords: redeclare, modification, constant
// status:   incorrect
//
// Checks that it's not allowed to modify a protected element with a replacement.
//

model M
  protected replaceable Real x;
end M;

model RedeclareVisibility2
  M m(replaceable Real x = 2.0);
end RedeclareVisibility2;

// Result:
// Error processing file: RedeclareVisibility2.mo
// [RedeclareVisibility2.mo:13:3-13:32:writable] Error: Variable m: Attempt to modify protected element m.x
// Error: Error occurred while flattening model RedeclareVisibility2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
