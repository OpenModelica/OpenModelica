// name: ConnectorBalance5
// keywords: connector
// status: correct
//
//

record R
  Real x;
end R;

connector C
  Real e;
  flow Real f;
  R r;
end C;

model ConnectorBalance5
  C c;
end ConnectorBalance5;

// Result:
// class ConnectorBalance5
//   Real c.e;
//   Real c.f;
//   Real c.r.x;
// equation
//   c.f = 0.0;
// end ConnectorBalance5;
// [flattening/modelica/connectors/ConnectorBalance5.mo:18:3-18:6:writable] Warning: Connector c is not balanced: The number of potential variables (2) is not equal to the number of flow variables (1).
//
// endResult
