// name: ProtectedMod1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  protected Real x = 1.0;
end A;

model ProtectedMod1
  A a(x = 2.0);
end ProtectedMod1;

// Result:
// Error processing file: ProtectedMod1.mo
// [flattening/modelica/scodeinst/ProtectedMod1.mo:13:7-13:14:writable] Notification: From here:
// [flattening/modelica/scodeinst/ProtectedMod1.mo:9:13-9:25:writable] Error: Protected element ‘x‘ may not be modified, got ‘x = 2.0‘.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
