// name: ExpandableConnectorComplex1
// keywords: expandable connector
// status: correct
//
// Checks that augmenting an expandable connector with a connector works.
//

expandable connector Bus
end Bus;

connector PositivePin
  Real v;
  flow Real i;
end PositivePin;

model M
  parameter Real A = 1;
  parameter Real w = 1;
  PositivePin a;
equation
  a.v = A*sin(w*time);
end M;

model ExpandableConnectorComplex1
  Bus bus;
  M m;
equation
  connect(m.a, bus.a);
end ExpandableConnectorComplex1;

// Result:
// class ExpandableConnectorComplex1
//   Real bus.a.i "virtual variable in expandable connector";
//   Real bus.a.v "virtual variable in expandable connector";
//   parameter Real m.A = 1.0;
//   parameter Real m.w = 1.0;
//   Real m.a.v;
//   Real m.a.i;
// equation
//   m.a.v = bus.a.v;
//   bus.a.i = 0.0;
//   m.a.i - bus.a.i = 0.0;
//   m.a.v = m.A * sin(m.w * time);
// end ExpandableConnectorComplex1;
// endResult
