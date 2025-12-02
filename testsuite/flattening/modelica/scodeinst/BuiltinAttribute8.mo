// name: BuiltinAttribute8
// keywords:
// status: incorrect
//


model A
  Real x(final start = 1.0);
end A;

model BuiltinAttribute8
  extends A(x(start = 2.0));
end BuiltinAttribute8;

// Result:
// Error processing file: BuiltinAttribute8.mo
// [flattening/modelica/scodeinst/BuiltinAttribute8.mo:12:15-12:26:writable] Notification: From here:
// [flattening/modelica/scodeinst/BuiltinAttribute8.mo:8:16-8:27:writable] Error: Trying to override final element start with modifier '= 2.0'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
