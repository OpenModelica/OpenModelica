// name: ConnectNonConnector2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ConnectNonConnector2
  type E = enumeration(a, b, c);
equation
  connect(E, E);
end ConnectNonConnector2;

// Result:
// Error processing file: ConnectNonConnector2.mo
// [flattening/modelica/scodeinst/ConnectNonConnector2.mo:10:3-10:16:writable] Error: Type name 'E' is not allowed in this context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
