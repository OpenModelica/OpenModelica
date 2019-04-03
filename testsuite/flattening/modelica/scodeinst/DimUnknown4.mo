// name: DimUnknown4
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model A
  Real x[:, :];
end A;

model B
  A a[2];
end B;

model DimUnknown4
  B b[4](each a(each x = 3.0));
end DimUnknown4;

// Result:
// Error processing file: DimUnknown4.mo
// [flattening/modelica/scodeinst/DimUnknown4.mo:17:22-17:29:writable] Notification: From here:
// [flattening/modelica/scodeinst/DimUnknown4.mo:9:3-9:15:writable] Error: Non-array modification ‘3.0‘ for array component ‘x‘, possibly due to missing ‘each‘.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
