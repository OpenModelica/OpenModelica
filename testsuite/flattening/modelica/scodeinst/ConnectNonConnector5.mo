// name: ConnectNonConnector5
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that a connector class can't be used as a connector.
//

connector C
  Real e;
  flow Real f;
end C;

model ConnectNonConnector5
  C c1, c2;
equation
  connect(C, c2);
end ConnectNonConnector5;

// Result:
// Error processing file: ConnectNonConnector5.mo
// [flattening/modelica/scodeinst/ConnectNonConnector5.mo:17:3-17:17:writable] Error: Expected C to be a component, but found class instead.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
