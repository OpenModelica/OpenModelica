// name: RedeclareConstant1
// keywords:
// status: incorrect
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
// Error processing file: RedeclareConstant1.mo
// [flattening/modelica/scodeinst/RedeclareConstant1.mo:9:3-9:36:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareConstant1.mo:13:7-13:29:writable] Error: Redeclaration of constant component x is not allowed.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
