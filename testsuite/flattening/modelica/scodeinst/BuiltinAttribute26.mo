// name: BuiltinAttribute26
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model BuiltinAttribute26
  parameter Real x_start[:, :] = {{1, 2, 3, 4}, {5, 6, 7, 8}};
  Real x[3](start = x_start[1]);
end BuiltinAttribute26;

// Result:
// Error processing file: BuiltinAttribute26.mo
// [flattening/modelica/scodeinst/BuiltinAttribute26.mo:9:13-9:31:writable] Notification: From here:
// [flattening/modelica/scodeinst/BuiltinAttribute26.mo:9:3-9:32:writable] Error: Type mismatch in binding 'start = x_start[1]', expected array dimensions [3], got [4].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
