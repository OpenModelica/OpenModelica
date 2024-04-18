// name:     RedeclareComponentInvalidDims1
// keywords: redeclare component
// status:   incorrect
// cflags: -d=newInst
//
// Checks that a redeclare of a component is not allowed to have dimensions on
// the type.
//

model A
  Real x[:];
end A;

model RedeclareComponentInvalidDims1
  extends A(redeclare A[2] x);
end RedeclareComponentInvalidDims1;

// Result:
// Error processing file: RedeclareComponentInvalidDims1.mo
// Failed to parse file: RedeclareComponentInvalidDims1.mo!
//
// [flattening/modelica/redeclare/RedeclareComponentInvalidDims1.mo:15:24-15:24:writable] Error: No viable alternative near token: [
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: RedeclareComponentInvalidDims1.mo!
//
// Execution failed!
// endResult
