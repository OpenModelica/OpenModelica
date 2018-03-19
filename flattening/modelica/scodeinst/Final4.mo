// name: Final4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  parameter Real x;
end A;

model B
  final A a(x = 1.0);
end B;

model Final4
  B b(a(x = 2.0));
end Final4;

// Result:
// Error processing file: Final4.mo
// [flattening/modelica/scodeinst/Final4.mo:16:7-16:17:writable] Notification: From here:
// [flattening/modelica/scodeinst/Final4.mo:12:3-12:21:writable] Error: Trying to override final element a with modifier '(x = 2.0)'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
