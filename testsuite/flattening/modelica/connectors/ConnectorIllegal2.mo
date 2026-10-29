// name: ConnectorIllegal2
// keywords: connector
// status: incorrect
//
// Tests an illegal connector definition
//

connector IllegalConnector
  Real a;
  flow Real b;
algorithm
  a := b;
end IllegalConnector;

model ConnectorIllegal2
  IllegalConnector ic;
end ConnectorIllegal2;

// Result:
// Error processing file: ConnectorIllegal2.mo
// [flattening/modelica/connectors/ConnectorIllegal2.mo:12:3-12:9:writable] Error: Algorithm sections are not allowed in connector.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
