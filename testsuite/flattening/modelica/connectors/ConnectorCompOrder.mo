// name:     ConnectorCompOrder
// keywords: connector, binding, modification, bug2159
// status:   correct
//
// Checks that order of the components in connectors doesn't matter.
//

connector C1
  flow Real f;
  Real e;
  stream Real s;
end C1;

connector C2
  stream Real s;
  flow Real f;
  Real e;
end C2;

model ConnectorCompOrder
  C1 c1;
  C2 c2;
equation
  connect(c1, c2);
end ConnectorCompOrder;

// Result:
// class ConnectorCompOrder
//   Real c1.f;
//   Real c1.e;
//   Real c1.s;
//   Real c2.s;
//   Real c2.f;
//   Real c2.e;
// equation
//   c1.f = 0.0;
//   c2.f = 0.0;
//   c1.e = c2.e;
//   (-c1.f) + (-c2.f) = 0.0;
//   c1.s = c2.s;
//   c2.s = c1.s;
// end ConnectorCompOrder;
// endResult
