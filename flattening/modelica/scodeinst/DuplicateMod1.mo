// name: DuplicateMod1.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  Real x;
end A;

model DuplicateMod1
  A a(x = 1, x = 2);
end DuplicateMod1;

// Result:
// Error processing file: DuplicateMod1.mo
// [flattening/modelica/scodeinst/DuplicateMod1.mo:12:14-12:19:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateMod1.mo:12:7-12:12:writable] Error: Duplicate modification of element x on component a.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
