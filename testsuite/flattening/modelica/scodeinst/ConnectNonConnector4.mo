// name: ConnectNonConnector4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ConnectNonConnector4
  Real x, y;
equation
  connect(x, y);
end ConnectNonConnector4;

// Result:
// Error processing file: ConnectNonConnector4.mo
// [flattening/modelica/scodeinst/ConnectNonConnector4.mo:10:3-10:16:writable] Error: x is not a valid connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
