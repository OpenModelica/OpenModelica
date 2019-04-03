// name: ConnectNonConnector3
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ConnectNonConnector3
equation
  for i in 1:3 loop
    connect(i, i);
  end for;
end ConnectNonConnector3;

// Result:
// Error processing file: ConnectNonConnector3.mo
// [flattening/modelica/scodeinst/ConnectNonConnector3.mo:10:5-10:18:writable] Error: i is not a valid connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
