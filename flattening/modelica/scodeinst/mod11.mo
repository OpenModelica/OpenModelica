// name: mod11.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//
//

model A
  Real x;
end A;

model B
  extends A(final x);
end B;

model C
  B b(x = 3);
end C;

// Result:
// Error processing file: mod11.mo
// [flattening/modelica/scodeinst/mod11.mo:17:7-17:12:writable] Notification: From here:
// [flattening/modelica/scodeinst/mod11.mo:13:19-13:20:writable] Error: Trying to override final element x with modifier '= 3'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
