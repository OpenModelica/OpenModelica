// name: DuplicateMod2.mo
// keywords:
// status: incorrect
//

model A
  Real x;
end A;

model DuplicateMod2
  extends A(x = 1, x = 2);
end DuplicateMod2;

// Result:
// - elab_untyped_mod (x = 1, x = 2) failed
// Error processing file: DuplicateMod2.mo
// [flattening/modelica/modification/DuplicateMod2.mo:11:20-11:25:writable] Notification: From here:
// [flattening/modelica/modification/DuplicateMod2.mo:11:13-11:18:writable] Error: Duplicate modification of element x on extends A.
// Error: Error occurred while flattening model DuplicateMod2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
