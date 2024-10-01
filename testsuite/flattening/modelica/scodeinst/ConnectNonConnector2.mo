// name: ConnectNonConnector2
// keywords:
// status: incorrect
//

model ConnectNonConnector2
  type E = enumeration(a, b, c);
equation
  connect(E, E);
end ConnectNonConnector2;

// Result:
// Error processing file: ConnectNonConnector2.mo
// [flattening/modelica/scodeinst/ConnectNonConnector2.mo:9:3-9:16:writable] Error: E is not a valid connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
