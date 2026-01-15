// name:     BreakComponentMod4
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
  extends A(m(x = 1));
end B;

model C
  extends B(break m);
end C;

model BreakComponentMod4
  extends C(m(x = 2));
end BreakComponentMod4;

// Result:
// Error processing file: BreakComponentMod4.mo
// [flattening/modelica/modification/BreakComponentMod4.mo:15:13-15:21:writable] Error: Modified element m not found in class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
