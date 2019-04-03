// name: Final5
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  parameter Real x;
end A;

model B
  A a(final x = 1.0);
end B;

model Final4
  B b(a(x = 2.0));
end Final4;

// Result:
// Error processing file: Final5.mo
// [flattening/modelica/scodeinst/Final5.mo:16:9-16:16:writable] Notification: From here:
// [flattening/modelica/scodeinst/Final5.mo:12:13-12:20:writable] Error: Trying to override final element x with modifier '= 2.0'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
