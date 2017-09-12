// name: dim15
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  Real x[:, :];
end A;

model B
  A a[2];
end B;

model C
  B b[4](each a(each x = 3.0));
end C;

// Result:
// Error processing file: dim15.mo
// [flattening/modelica/scodeinst/dim15.mo:17:22-17:29:writable] Error: Type mismatch in binding x = 3, expected subtype of Real[:, :], got type Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
