// name: DuplicateMod4.mo
// keywords:
// status: incorrect
//

model A
  replaceable Real x;
end A;

model DuplicateMod4
  A a(redeclare Real x = 1, x = 2);
end DuplicateMod4;

// Result:
// Error processing file: DuplicateMod4.mo
// [flattening/modelica/modification/DuplicateMod4.mo:11:29-11:34:writable] Notification: From here:
// [flattening/modelica/modification/DuplicateMod4.mo:11:7-11:27:writable] Error: Duplicate modification of element x on component a.
// Error: Error occurred while flattening model DuplicateMod4
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
