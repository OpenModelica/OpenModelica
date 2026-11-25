// name: ExpandableConnector7
// keywords: expandable connector
// status: correct
//
//

connector RealOutput = output Real;

expandable connector EC
  RealOutput x;
end EC;

expandable connector EC2
  EC ec;
end EC2;

model ExpandableConnector7
  RealOutput x;
  EC2 ec1, ec2;
equation
  connect(ec1.ec.x, x);
  connect(ec1, ec2);
end ExpandableConnector7;

// Result:
// class ExpandableConnector7
//   output Real x;
//   output Real ec1.ec.x;
//   output Real ec2.ec.x;
// equation
//   ec1.ec.x = ec2.ec.x;
//   ec1.ec.x = x;
// end ExpandableConnector7;
// endResult
