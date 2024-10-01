// name: RedeclareComponentClass
// keywords:
// status: incorrect
//
// Checks that a component can't be redeclared as a class.
//

model A
  replaceable Real x;
end A;

model RedeclareComponentClass
  A a(redeclare model x = A);
end RedeclareComponentClass;

// Result:
// Error processing file: RedeclareComponentClass.mo
// [flattening/modelica/scodeinst/RedeclareComponentClass.mo:13:17-13:28:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareComponentClass.mo:9:3-9:21:writable] Error: Invalid redeclaration of component x as class.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
