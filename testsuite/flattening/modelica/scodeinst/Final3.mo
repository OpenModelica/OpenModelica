// name: Final3
// keywords:
// status: incorrect
//

model A
  final parameter Real x;
end A;

model Final3
  A a(x = 1.0);
end Final3;

// Result:
// Error processing file: Final3.mo
// [flattening/modelica/scodeinst/Final3.mo:11:7-11:14:writable] Notification: From here:
// [flattening/modelica/scodeinst/Final3.mo:7:3-7:25:writable] Error: Trying to override final element x with modifier '= 1.0'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
