// name:     BreakComponentInvalid2
// keywords: modification break
// status:   incorrect
//

model A
  class x end x;
end A;

model BreakComponentInvalid2
  extends A(break x);
end BreakComponentInvalid2;

// Result:
// Error processing file: BreakComponentInvalid2.mo
// [flattening/modelica/modification/BreakComponentInvalid2.mo:11:13-11:20:writable] Error: Invalid use of break on non-component 'x'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
