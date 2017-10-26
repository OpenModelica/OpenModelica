// name: ConnectNonConnector6
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that a connector member that isn't itself a connector isn't allowed in
// a connection.
//

connector C1
  Real x;
end C1;

connector C2
  C1 c;
  flow Real f;
end C2;

model ConnectNonConnector6
  C2 c1, c2;
equation
  connect(c1.f, c2.c);
end ConnectNonConnector6;

// Result:
// Error processing file: ConnectNonConnector6.mo
// [flattening/modelica/scodeinst/ConnectNonConnector6.mo:22:3-22:22:writable] Error: c1.f is not a valid connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
