// name:     BreakComponentMod2
// keywords: modification break
// status:   incorrect
//

model M
  Real x;
end M;

model A
  M m;
end A;

model B
  extends A(break m);
end B;

model BreakComponentMod2
  extends B(m(x = 1));
end BreakComponentMod2;

// Result:
// Error processing file: BreakComponentMod2.mo
// [flattening/modelica/modification/BreakComponentMod2.mo:19:13-19:21:writable] Error: Modified element m not found in class B.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
