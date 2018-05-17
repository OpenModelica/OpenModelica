// name: BuiltinAttribute5
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BuiltinAttribute5
  Real x(start = "fish");
end BuiltinAttribute5;

// Result:
// Error processing file: BuiltinAttribute5.mo
// [flattening/modelica/scodeinst/BuiltinAttribute5.mo:8:10-8:24:writable] Notification: From here:
// [flattening/modelica/scodeinst/BuiltinAttribute5.mo:8:3-8:25:writable] Error: Type mismatch in binding start = "fish", expected subtype of Real, got type String.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
