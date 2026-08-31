// name:     BreakComponentInvalid7
// keywords: modification break
// status:   incorrect
//

model A
  Real x[3];
end A;

model BreakComponentInvalid7
  extends A(break a[2]);
end BreakComponentInvalid7;

// Result:
// Error processing file: BreakComponentInvalid7.mo
// Failed to parse file: BreakComponentInvalid7.mo!
//
// [flattening/modelica/modification/BreakComponentInvalid7.mo:11:20-11:20:writable] Error: Missing token: ')'
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: BreakComponentInvalid7.mo!
//
// Execution failed!
// endResult
