// name:     BreakConnectInvalid3
// keywords: modification break
// status:   incorrect
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c1, c2;
equation
  connect(c1, c2);
end A;

model BreakConnectInvalid3
  extends A(break c1, break connect(c1, c2));
end BreakConnectInvalid3;

// Result:
// Error processing file: BreakConnectInvalid3.mo
// [flattening/modelica/modification/BreakConnectInvalid3.mo:18:23-18:44:writable] Error: No matching element found for 'break connect(c1, c2)'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
