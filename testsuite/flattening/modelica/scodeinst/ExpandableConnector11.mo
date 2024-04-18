// name: ExpandableConnector11
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
//

model A
  expandable connector Bus
  end Bus;

  Bus bus;
end A;

model ExpandableConnector11
  expandable connector Bus
    Real x;
  end Bus;

  Bus bus;
  A a;
equation
  connect(bus, a.bus);
end ExpandableConnector11;

// Result:
// class ExpandableConnector11
// end ExpandableConnector11;
// endResult
