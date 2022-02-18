// name: ProtectedMod3
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  protected Real x = 1.0;
end A;

model B
  A a;
end B;

model ProtectedMod3
  extends B(a(x = 2.0));
end ProtectedMod3;

// Result:
// Error processing file: ProtectedMod3.mo
// [flattening/modelica/scodeinst/ProtectedMod3.mo:17:15-17:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/ProtectedMod3.mo:9:13-9:25:writable] Error: Protected element ‘x‘ may not be modified, got ‘x = 2.0‘.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
