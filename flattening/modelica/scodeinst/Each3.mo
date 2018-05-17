// name: Each3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  Real n[2];
end A;

model Each3
  A a(each n(fixed=true));
end Each3;

// Result:
// Error processing file: Each3.mo
// [flattening/modelica/scodeinst/Each3.mo:12:12-12:25:writable] Warning: 'each' used when modifying non-array element a.
// [flattening/modelica/scodeinst/Each3.mo:12:14-12:24:writable] Notification: From here:
// [flattening/modelica/scodeinst/Each3.mo:8:3-8:12:writable] Error: Type mismatch in binding fixed = true, expected subtype of Boolean[2], got type Boolean.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
