// name: ExpandableConnectorPresent2
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
//

expandable connector EC1
  Real x;
end EC1;

expandable connector EC2
  EC1 ec1;
  EC1 ec2;
end EC2;

model ExpandableConnectorPresent2
  EC2 ec2;
end ExpandableConnectorPresent2;

// Result:
// class ExpandableConnectorPresent2
// end ExpandableConnectorPresent2;
// endResult
