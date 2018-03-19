// name: RedeclareConstant1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that constants aren't allowed to be redeclared.
// 

model A
  replaceable constant Real x = 1.0;
end A;

model RedeclareConstant1
  A a(redeclare Real x = 2.0);
end RedeclareConstant1;

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
