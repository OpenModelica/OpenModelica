// name: ExpandableConnector6
// keywords: expandable connector
// status: correct
//
//

expandable connector EC
end EC;

model ExpandableConnector6
  connector RealOutput = output Real;
  RealOutput x;
  EC ec1, ec2;
equation
  connect(ec1, ec2);
  connect(ec1.x, x);
end ExpandableConnector6;

// Result:
// class ExpandableConnector6
//   Real ec1.x "virtual variable in expandable connector";
//   Real ec2.x "virtual variable in expandable connector";
//   output Real x;
// equation
//   ec1.x = ec2.x;
//   ec1.x = x;
// end ExpandableConnector6;
// endResult
