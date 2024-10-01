// name: ConnectorBalance3
// keywords: connector
// status: correct
//
//

connector C
  Real e;
end C;

model ConnectorBalance3
  C c;
end ConnectorBalance3;

// Result:
// class ConnectorBalance3
//   Real c.e;
// end ConnectorBalance3;
// [flattening/modelica/connectors/ConnectorBalance3.mo:12:3-12:6:writable] Warning: Connector c is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
//
// endResult
