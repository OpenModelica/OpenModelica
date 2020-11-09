// name: ConnectorIllegal3
// keywords: connector
// status: correct
// cflags: -d=-newInst
//
// Tests an illegal connector definition
//

connector IllegalConnector = Real;

model ConnectorIllegal3
  IllegalConnector ic;
end ConnectorIllegal3;

// Result:
// class ConnectorIllegal3
//   Real ic;
// end ConnectorIllegal3;
// [flattening/modelica/connectors/ConnectorIllegal3.mo:9:1-9:34:writable] Warning: Connector .IllegalConnector is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
//
// endResult
