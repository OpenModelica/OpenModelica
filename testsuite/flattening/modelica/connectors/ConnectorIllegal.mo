// name: ConnectorIllegal
// keywords: connector
// status: incorrect
// cflags: -d=-newInst
//
// Tests an illegal connector definition
//

connector IllegalConnector
  Integer i;
  flow Real f;
equation
  i = 2;
end IllegalConnector;

model ConnectorIllegal
  IllegalConnector ic;
end ConnectorIllegal;

// Result:
// Error processing file: ConnectorIllegal.mo
// [flattening/modelica/connectors/ConnectorIllegal.mo:13:3-13:8:writable] Error: Equations are not allowed in connector.
// Error: Error occurred while flattening model ConnectorIllegal
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
