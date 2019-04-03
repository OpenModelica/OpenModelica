// name: mod5.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//


model A
  Real x;
end A;

model B
  A a(y = 2.0);
end B;

// Result:
// Error processing file: mod5.mo
// [flattening/modelica/scodeinst/mod5.mo:13:7-13:14:writable] Error: Modified element y not found in class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
