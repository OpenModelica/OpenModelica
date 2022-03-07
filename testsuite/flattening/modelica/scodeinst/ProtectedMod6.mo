// name: ProtectedMod6
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  Real x = 1.0;
end A;

model B
protected
  extends A;
end B;

model ProtectedMod6
  B b(x = 2.0);
end ProtectedMod6;

// Result:
// Error processing file: ProtectedMod6.mo
// [flattening/modelica/scodeinst/ProtectedMod6.mo:18:7-18:14:writable] Notification: From here:
// [flattening/modelica/scodeinst/ProtectedMod6.mo:9:3-9:15:writable] Error: Protected element ‘x‘ may not be modified, got ‘x = 2.0‘.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
