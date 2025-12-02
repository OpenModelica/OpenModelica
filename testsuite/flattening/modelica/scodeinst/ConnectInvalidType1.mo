// name: ConnectInvalidType1
// keywords:
// status: incorrect
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
// [flattening/modelica/scodeinst/ConnectInvalidType1.mo:14:3-14:18:writable] Error: The connectors in connect(c1, c2) are not type compatible.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
