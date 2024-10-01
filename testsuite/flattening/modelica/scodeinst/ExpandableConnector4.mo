// name: ExpandableConnector4
// keywords: expandable connector
// status: correct
//
//

expandable connector EC
end EC;

model A
  connector RealOutput = output Real;
  RealOutput y = 0;
  EC ec;
equation
  connect(ec.y, y);
end A;

model ExpandableConnector4
  A a[3];
end ExpandableConnector4;

// Result:
// class ExpandableConnector4
//   Real a[3].ec.y "virtual variable in expandable connector";
//   Real a[2].ec.y "virtual variable in expandable connector";
//   Real a[1].ec.y "virtual variable in expandable connector";
//   Real a[1].y = 0.0;
//   Real a[2].y = 0.0;
//   Real a[3].y = 0.0;
// equation
//   a[1].ec.y = a[1].y;
//   a[2].ec.y = a[2].y;
//   a[3].ec.y = a[3].y;
// end ExpandableConnector4;
// endResult
