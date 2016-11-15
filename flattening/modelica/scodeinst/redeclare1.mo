// name: redeclare1.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  Real x;
end A;

model C
  replaceable model M = A;
  M m;
end C;

model D
  extends C(redeclare Real M);
end D;

// Result:
// Error processing file: redeclare1.mo
// [redeclare1.mo:21:3-21:30:writable] Notification: From here:
// [redeclare1.mo:17:15-17:26:writable] Error: Invalid redeclaration of model M as a component.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
