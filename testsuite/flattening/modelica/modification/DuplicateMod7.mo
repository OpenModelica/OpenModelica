// name: DuplicateMod7.mo
// keywords:
// status: incorrect
// cflags: -d=-newInst
//

model A
  Real x;
end A;

model DuplicateMod7
  model A2 = A(x = 1.0, x = 2.0);
  A2 a;
end DuplicateMod7;

// Result:
// Error processing file: DuplicateMod7.mo
// [flattening/modelica/modification/DuplicateMod7.mo:12:25-12:32:writable] Notification: From here:
// [flattening/modelica/modification/DuplicateMod7.mo:12:16-12:23:writable] Error: Duplicate modification of element x on inherited class A.
// [flattening/modelica/modification/DuplicateMod7.mo:12:25-12:32:writable] Notification: From here:
// [flattening/modelica/modification/DuplicateMod7.mo:12:16-12:23:writable] Error: Duplicate modification of element x on inherited class A.
// Error: Error occurred while flattening model DuplicateMod7
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
