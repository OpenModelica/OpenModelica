// name: DuplicateMod3.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  Real x;
end A;

model B
  A a;
end B;

model DuplicateMod3
  B b(a(x = 4), a(x = 6));
end DuplicateMod3;

// Result:
// Error processing file: DuplicateMod3.mo
// [flattening/modelica/scodeinst/DuplicateMod3.mo:16:9-16:14:writable] Notification: From here:
// [flattening/modelica/scodeinst/DuplicateMod3.mo:16:19-16:24:writable] Error: Duplicate modification of element a.x on component b.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
