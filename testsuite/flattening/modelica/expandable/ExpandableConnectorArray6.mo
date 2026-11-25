// name: ExpandableConnectorArray6
// keywords: expandable connector
// status: correct
// suite: disabled
//

model ExpandableConnectorArray6
  expandable connector EC
  end EC;

  connector RealOutput = output Real;

  model M
    RealOutput ro = 1.0;
  end M;

  EC ec;
  M m;
equation
  connect(m.ro, ec.ro[1]);
end ExpandableConnectorArray6;

// Result:
// class ExpandableConnectorArray6
//   Real ec.ro[1] "variable added to expandable connector";
//   Real m.ro = 1.0;
// equation
//   m.ro = ec.ro[1];
// end ExpandableConnectorArray6;
// endResult
