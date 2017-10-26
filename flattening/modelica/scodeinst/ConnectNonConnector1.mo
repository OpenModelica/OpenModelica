// name: ConnectNonConnector1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ConnectNonConnector1
equation
  connect(Boolean, Boolean);
end ConnectNonConnector1;

// Result:
// Error processing file: ConnectNonConnector1.mo
// [flattening/modelica/scodeinst/ConnectNonConnector1.mo:9:3-9:28:writable] Error: Type name 'Boolean' is not allowed in this context.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
