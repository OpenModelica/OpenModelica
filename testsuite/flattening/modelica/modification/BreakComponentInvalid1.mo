// name:     BreakComponentInvalid1
// keywords: modification break
// status:   incorrect
//

model A
end A;

model BreakComponentInvalid1
  extends A(break x);
end BreakComponentInvalid1;

// Result:
// Error processing file: BreakComponentInvalid1.mo
// [flattening/modelica/modification/BreakComponentInvalid1.mo:10:13-10:20:writable] Error: Modified element x not found in class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
