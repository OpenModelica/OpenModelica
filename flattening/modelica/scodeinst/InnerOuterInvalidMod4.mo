// name: InnerOuterInvalidMod4
// keywords: 
// status: incorrect
// cflags: -d=newInst
//

model A
  outer model M = B(x = 1.0);
  M m;
end A;

model B
  Real x;
end B;

model InnerOuterInvalidMod4
  inner model M = B(x = 2.0);
  A a;
end InnerOuterInvalidMod4;

// Result:
// Error processing file: InnerOuterInvalidMod4.mo
// [flattening/modelica/scodeinst/InnerOuterInvalidMod4.mo:8:9-8:29:writable] Error: Modifier '(x = 1.0)' found on outer element M.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
