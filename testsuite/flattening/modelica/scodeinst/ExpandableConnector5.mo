// name: ExpandableConnector5
// keywords: expandable connector
// status: correct
//
//

expandable connector EC
end EC;

model ExpandableConnector5
  connector RealOutput = output Real;
  RealOutput y[2] = zeros(size(y, 1));
  EC ec;
equation
  connect(ec.y, y[1]);
end ExpandableConnector5;

// Result:
// class ExpandableConnector5
//   Real ec.y "virtual variable in expandable connector";
//   output Real y[1];
//   output Real y[2];
// equation
//   ec.y = y[1];
//   y = {0.0, 0.0};
// end ExpandableConnector5;
// endResult
