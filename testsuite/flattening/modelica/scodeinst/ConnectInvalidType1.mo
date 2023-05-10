// name: ConnectInvalidType1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

connector C
  Real e;
  flow Real f;
end C;

model ConnectInvalidType1
  C c1, c2[2];
equation
  connect(c1, c2);
end ConnectInvalidType1;

// Result:
// Error processing file: ConnectInvalidType1.mo
// [flattening/modelica/scodeinst/ConnectInvalidType1.mo:15:3-15:18:writable] Error: The connectors in connect(c1, c2) are not type compatible.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
