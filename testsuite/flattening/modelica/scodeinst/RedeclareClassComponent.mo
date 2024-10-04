// name: RedeclareClassComponent
// keywords:
// status: incorrect
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
// [flattening/modelica/scodeinst/RedeclareClassComponent.mo:18:13-18:29:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareClassComponent.mo:13:15-13:26:writable] Error: Invalid redeclaration of class M as component.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
