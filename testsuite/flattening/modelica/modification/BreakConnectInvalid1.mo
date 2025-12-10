// name:     BreakConnectInvalid1
// keywords: modification break
// status:   incorrect
//

model A
end A;

model BreakConnectInvalid1
  extends A(break connect(c1, c2));
end BreakConnectInvalid1;

// Result:
// Error processing file: BreakConnectInvalid1.mo
// [flattening/modelica/modification/BreakConnectInvalid1.mo:10:13-10:34:writable] Error: No matching element found for 'break connect(c1, c2)'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
