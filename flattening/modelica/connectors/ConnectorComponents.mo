// name: ConnectorComponents
// keywords: connector
// status: correct
//
// Tests declaration and instantiation of a connector with components
//

connector TestConnector
  Real r;
  flow Real f;
end TestConnector;

model ConnectorComponents
  TestConnector tc1;
  Real r;
equation
  tc1.r = 3.0;
  r = tc1.r;
end ConnectorComponents;

// Result:
// class ConnectorComponents
//   Real tc1.r;
//   Real tc1.f;
//   Real r;
// equation
//   tc1.r = 3.0;
//   r = tc1.r;
//   tc1.f = 0.0;
// end ConnectorComponents;
// endResult
