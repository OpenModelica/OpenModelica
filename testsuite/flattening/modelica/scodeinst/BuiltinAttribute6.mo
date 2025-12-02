// name: BuiltinAttribute6
// keywords:
// status: incorrect
//

model BuiltinAttribute6
  Real x(quantity = 1);
end BuiltinAttribute6;

// Result:
// Error processing file: BuiltinAttribute6.mo
// [flattening/modelica/scodeinst/BuiltinAttribute6.mo:7:10-7:22:writable] Notification: From here:
// [flattening/modelica/scodeinst/BuiltinAttribute6.mo:7:3-7:23:writable] Error: Type mismatch in binding quantity = 1, expected subtype of String, got type Integer.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
