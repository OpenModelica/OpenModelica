// name: BuiltinAttribute6
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BuiltinAttribute6
  Real x(quantity = 1);
end BuiltinAttribute6;

// Result:
// Error processing file: BuiltinAttribute6.mo
// [flattening/modelica/scodeinst/BuiltinAttribute6.mo:8:10-8:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/BuiltinAttribute6.mo:8:3-8:23:writable] Error: Type mismatch in binding quantity = 1, expected subtype of String, got type Integer.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
