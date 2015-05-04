// name:     RedeclareComponentInvalid3
// keywords: redeclare component
// status:   incorrect
//
// Tests that it's only allowed to redeclare a component marked as replaceable.
//

class C
  Real r;
end C;

class RedeclareComponentInvalid3
  extends C;

  redeclare Real r(start = 1.0);
end RedeclareComponentInvalid3;

// Result:
// Error processing file: RedeclareComponentInvalid3.mo
// [RedeclareComponentInvalid3.mo:9:3-9:9:writable] Error: Trying to redeclare non-replaceable component r.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
