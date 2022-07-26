// name: ConnectorBalance1
// keywords: connector
// status: correct
// cflags: -d=newInst
//
// Tests an illegal connector definition
//

connector IllegalConnector = Real;

model ConnectorBalance1
  IllegalConnector ic;
end ConnectorBalance1;

// Result:
// class ConnectorBalance1
//   Real ic;
// end ConnectorBalance1;
// [flattening/modelica/connectors/ConnectorBalance1.mo:12:3-12:22:writable] Warning: Connector ic is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
//
// endResult
