// name: ConnectorIllegal4
// keywords: connector
// status: correct
// cflags: -d=-newInst
//
// Tests an illegal connector definition
//

connector IllegalConnector = flow Real;

model ConnectorIllegal4
  IllegalConnector ic;
end ConnectorIllegal4;

// Result:
// class ConnectorIllegal4
//   Real ic;
// end ConnectorIllegal4;
// [flattening/modelica/connectors/ConnectorIllegal4.mo:9:1-9:39:writable] Warning: Connector .IllegalConnector is not balanced: The number of potential variables (0) is not equal to the number of flow variables (1).
//
// endResult
