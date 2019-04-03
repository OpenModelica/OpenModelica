// name: RedeclareClassComponent
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Check that a class can't be redeclared as a component.
// 

model A
  Real x;
end A;

model C
  replaceable model M = A;
  M m;
end C;

model RedeclareClassComponent
  extends C(redeclare Real M);
end RedeclareClassComponent;

// Result:
// Error processing file: RedeclareClassComponent.mo
// [flattening/modelica/scodeinst/RedeclareClassComponent.mo:19:13-19:29:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareClassComponent.mo:14:15-14:26:writable] Error: Invalid redeclaration of class M as component.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
