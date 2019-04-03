// name: ExpandableConnectorFlow2
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
// Expandable connectors may not contain elements declared as flow, but may
// contain non-expandable connector components with flow components.
//

connector C
  flow Real f;
  Real e;
end C;

expandable connector Bus
  C c;
end Bus;

model ExpandableConnectorFlow2
  Bus bus;
  C c;
equation
  connect(bus.c, c);
end ExpandableConnectorFlow2;

// Result:
// class ExpandableConnectorFlow2
//   Real c.f;
//   Real c.e;
// equation
//   bus.c.f = 0.0;
//   c.f = 0.0;
// end ExpandableConnectorFlow2;
// endResult
