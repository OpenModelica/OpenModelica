// name: ExpandableConnectorArray3
// keywords: expandable connector
// status: correct
//

expandable connector EC
end EC;

expandable connector EC2
  Real x;
end EC2;

model ExpandableConnectorArray3
  EC ec[3];
  EC2 ec2[3];
equation
  connect(ec, ec2);
end ExpandableConnectorArray3;

// Result:
// class ExpandableConnectorArray3
// end ExpandableConnectorArray3;
// endResult
