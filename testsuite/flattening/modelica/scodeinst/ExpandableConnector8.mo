// name: ExpandableConnector8
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

expandable connector EC3
  EC2 ec2;
end EC3;

model ExpandableConnector8
  RealOutput x;
  EC3 ec1, ec2;
equation
  connect(ec1.ec2.ec.x, x);
  connect(ec1, ec2);
end ExpandableConnector8;

// Result:
// class ExpandableConnector8
//   output Real x;
//   output Real ec1.ec2.ec.x;
//   output Real ec2.ec2.ec.x;
// equation
//   ec1.ec2.ec.x = ec2.ec2.ec.x;
//   ec1.ec2.ec.x = x;
// end ExpandableConnector8;
// endResult
