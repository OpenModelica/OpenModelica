// name: InnerOuterInvalidMod5
// keywords: 
// status: incorrect
// cflags: -d=newInst
//

model A
  outer replaceable model M = B;
  M m;
end A;

model B
  Real x;
end B;

model InnerOuterInvalidMod5
  inner model M = B(x = 2.0);
  A a(redeclare model M = B(x = 1.0));
end InnerOuterInvalidMod5;

// Result:
// Error processing file: InnerOuterInvalidMod5.mo
// [flattening/modelica/scodeinst/InnerOuterInvalidMod5.mo:18:17-18:37:writable] Error: Modifier 'redeclare model M = B(x = 1.0)' found on outer element M.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
