// name:     BreakComponentInvalid6
// keywords: modification break
// status:   incorrect
//

model A
  Real x;
end A;

model B
  A a;
equation
  a.x = 1.0;
end B;

model BreakComponentInvalid6
  extends B(break a);
end BreakComponentInvalid6;

// Result:
// Error processing file: BreakComponentInvalid6.mo
// [flattening/modelica/modification/BreakComponentInvalid6.mo:13:3-13:12:writable] Error: Variable a.x not found in scope B.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
