// name: ExpandableConnector10
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
//

connector FluidPort
  flow Real m_flow;
  Real p;
  stream Real h_outflow;
end FluidPort;

connector FluidPort_a
  extends FluidPort;
end FluidPort_a;

expandable connector Bus
  FluidPort_a port_1;
end Bus;

model ExpandableConnector10
  Bus bus;
end ExpandableConnector10;

// Result:
// class ExpandableConnector10
// end ExpandableConnector10;
// endResult
