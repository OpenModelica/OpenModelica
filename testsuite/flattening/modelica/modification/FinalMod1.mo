// name:     FinalMod1
// keywords: final modification #2964
// status:   incorrect
// cflags: -d=-newInst
//
// Tests that the compiler gives an error when trying to modify a final element.
//

model A
  Real x = 10;
  final Real y = 20;
end A;

model B
  A a(x = 15, y = 30);
end B;

// Result:
// Error processing file: FinalMod1.mo
// [flattening/modelica/modification/FinalMod1.mo:11:3-11:20:writable] Notification: From here:
// [flattening/modelica/modification/FinalMod1.mo:15:15-15:21:writable] Error: Trying to override final element y with modifier ' = 30'.
// Error: Error occurred while flattening model B
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
