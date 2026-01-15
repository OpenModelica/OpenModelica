// name:     BreakConnectInvalid2
// keywords: modification break
// status:   incorrect
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c1, c2, c3;
equation
  connect(c1, c2);
  connect(c2, c3);
end A;

model BreakConnectInvalid2
  extends A(break connect(c1, c3));
end BreakConnectInvalid2;

// Result:
// Error processing file: BreakConnectInvalid2.mo
// [flattening/modelica/modification/BreakConnectInvalid2.mo:19:13-19:34:writable] Error: No matching element found for 'break connect(c1, c3)'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
