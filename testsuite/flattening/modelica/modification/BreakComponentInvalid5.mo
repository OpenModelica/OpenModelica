// name:     BreakComponentInvalid5
// keywords: modification break
// status:   incorrect
//

record R
  Real x;
  Real y;
end R;

model A
  R r;
end A;

model BreakComponentInvalid5
  extends A(break r);
end BreakComponentInvalid5;

// Result:
// Error processing file: BreakComponentInvalid5.mo
// [flattening/modelica/modification/BreakComponentInvalid5.mo:16:13-16:20:writable] Notification: From here:
// [flattening/modelica/modification/BreakComponentInvalid5.mo:12:3-12:6:writable] Error: Invalid use of break on component 'r', component must be a model, block, or connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
