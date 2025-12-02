// name: ConnectorBalance7
// keywords: connector
// status: correct
//
//

connector C1
  Real e1;
  flow Real f1;
  stream Real s1;
end C1;

connector C2
  Real e2;
  flow Real f2;
end C2;

connector HC
  C1 c1;
  C2 c2;
end HC;

model ConnectorBalance7
  HC hc;
end ConnectorBalance7;

// Result:
// class ConnectorBalance7
//   Real hc.c1.e1;
//   Real hc.c1.f1;
//   Real hc.c1.s1;
//   Real hc.c2.e2;
//   Real hc.c2.f2;
// equation
//   hc.c1.f1 = 0.0;
//   hc.c2.f2 = 0.0;
// end ConnectorBalance7;
// endResult
