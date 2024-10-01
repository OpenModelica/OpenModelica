// name: ExpandableConnector14
// keywords: expandable connector
// status: correct
//

expandable connector EC
end EC;

expandable connector EC2
  Real x;
end EC2;

model ExpandableConnector14
  EC ec[3];
  EC2 ec2[3];
equation
  connect(ec, ec2);
end ExpandableConnector14;

// Result:
// class ExpandableConnector14
// end ExpandableConnector14;
// endResult
