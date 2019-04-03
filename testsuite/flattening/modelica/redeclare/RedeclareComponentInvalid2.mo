// name:     RedeclareComponentInvalid2
// keywords: redeclare component
// status:   incorrect
//
// Tests that only inherited components can be redeclared.
//

class RedeclareComponentInvalid2
  replaceable Real r;
  redeclare Real r(start = 1.0);
end RedeclareComponentInvalid2;

// Result:
// Error processing file: RedeclareComponentInvalid2.mo
// [RedeclareComponentInvalid2.mo:10:3-10:32:writable] Error: No inherited component named r found.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
