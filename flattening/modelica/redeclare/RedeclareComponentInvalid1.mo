// name:     RedeclareComponentInvalid1
// keywords: redeclare component
// status:   incorrect
//
// Tests that a component redeclaration needs a corresponding inherited
// component to redeclare.
//

class RedeclareComponentInvalid1
  redeclare Real r;
end RedeclareComponentInvalid1;

// Result:
// Error processing file: RedeclareComponentInvalid1.mo
// [RedeclareComponentInvalid1.mo:10:3-10:19:writable] Error: No inherited component named r found.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
