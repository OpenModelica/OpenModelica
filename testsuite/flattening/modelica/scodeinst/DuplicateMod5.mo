// name: DuplicateMod5.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  Real x;
end A;

model B
  replaceable A a;
end B;

model DuplicateMod5
  B b(redeclare A a(x = 5), a(x = 1));
end DuplicateMod5;

// Result:
// Error processing file: DuplicateMod5.mo
// [flattening/modelica/scodeinst/DuplicateMod5.mo:16:29-16:37:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateMod5.mo:16:7-16:27:writable] Error: Duplicate modification of element a on component b.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
