// name: DuplicateMod4.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  replaceable Real x;
end A;

model DuplicateMod4
  A a(redeclare Real x = 1, x = 2);
end DuplicateMod4;

// Result:
// Error processing file: DuplicateMod4.mo
// [flattening/modelica/scodeinst/DuplicateMod4.mo:12:29-12:34:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateMod4.mo:12:7-12:27:writable] Error: Duplicate modification of element x on component a.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
