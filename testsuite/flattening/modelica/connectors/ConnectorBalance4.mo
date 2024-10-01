// name: ConnectorBalance4
// keywords: connector
// status: correct
//
//

connector C
  Real e1;
  Real e2;
  Real e3;
  flow Real f[3];
end C;

model ConnectorBalance4
  C c;
end ConnectorBalance4;

// Result:
// class ConnectorBalance4
//   Real c.e1;
//   Real c.e2;
//   Real c.e3;
//   Real c.f[1];
//   Real c.f[2];
//   Real c.f[3];
// equation
//   c.f[1] = 0.0;
//   c.f[2] = 0.0;
//   c.f[3] = 0.0;
// end ConnectorBalance4;
// endResult
