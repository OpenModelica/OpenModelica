// name: Final5
// keywords:
// status: incorrect
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
// [flattening/modelica/scodeinst/Final5.mo:15:9-15:16:writable] Notification: From here:
// [flattening/modelica/scodeinst/Final5.mo:11:13-11:20:writable] Error: Trying to override final element x with modifier '= 2.0'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
