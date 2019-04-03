// name: DuplicateMod1.mo
// keywords:
// status: incorrect
//

model A
  Real x;
end A;

model DuplicateMod1
  A a(x = 1, x = 2);
end DuplicateMod1;

// Result:
// Error processing file: DuplicateMod1.mo
// [flattening/modelica/modification/DuplicateMod1.mo:11:14-11:19:writable] Notification: From here:
// [flattening/modelica/modification/DuplicateMod1.mo:11:7-11:12:writable] Error: Duplicate modification of element x on component a.
// Error: Error occurred while flattening model DuplicateMod1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
