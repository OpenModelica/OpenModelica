// name: BuiltinAttribute8
// keywords:
// status: incorrect
// cflags: -d=newInst
//


model A
  Real x(final start = 1.0);
end A;

model BuiltinAttribute8
  extends A(x(start = 2.0));
end BuiltinAttribute8;

// Result:
// Error processing file: BuiltinAttribute8.mo
// [flattening/modelica/scodeinst/BuiltinAttribute8.mo:13:15-13:26:writable] Notification: From here:
// [flattening/modelica/scodeinst/BuiltinAttribute8.mo:9:16-9:27:writable] Error: Trying to override final element start with modifier '= 2.0'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
