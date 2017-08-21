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
// [flattening/modelica/scodeinst/redeclare1.mo:17:13-17:29:writable] Notification: From here:
// [flattening/modelica/scodeinst/redeclare1.mo:12:15-12:26:writable] Error: Invalid redeclaration of class M as component.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
