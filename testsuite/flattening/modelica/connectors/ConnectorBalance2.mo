// name: ConnectorBalance2
// keywords: connector
// status: correct
// cflags: -d=newInst
//
// Tests an illegal connector definition
//

connector IllegalConnector = flow Real;

model ConnectorBalance2
  IllegalConnector ic;
end ConnectorBalance2;

// Result:
// class ConnectorBalance2
//   Real ic;
// equation
//   ic = 0.0;
// end ConnectorBalance2;
// [flattening/modelica/connectors/ConnectorBalance2.mo:12:3-12:22:writable] Warning: Connector ic is not balanced: The number of potential variables (0) is not equal to the number of flow variables (1).
//
// endResult
