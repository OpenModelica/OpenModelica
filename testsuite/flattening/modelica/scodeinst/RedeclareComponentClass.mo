// name: RedeclareComponentClass
// keywords:
// status: incorrect
// cflags: -d=newInst
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
// [flattening/modelica/scodeinst/RedeclareComponentClass.mo:14:17-14:28:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareComponentClass.mo:10:3-10:21:writable] Error: Invalid redeclaration of component x as class.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
