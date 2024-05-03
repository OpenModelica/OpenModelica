// name: BuiltinAttribute25
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BuiltinAttribute25
  parameter Real x_start[:] = {1, 2};
  Real x[3](start = x_start);
end BuiltinAttribute25;

// Result:
// Error processing file: BuiltinAttribute25.mo
// [flattening/modelica/scodeinst/BuiltinAttribute25.mo:9:13-9:28:writable] Notification: From here:
// [flattening/modelica/scodeinst/BuiltinAttribute25.mo:9:3-9:29:writable] Error: Type mismatch in binding 'start = x_start', expected array dimensions [3], got [2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
