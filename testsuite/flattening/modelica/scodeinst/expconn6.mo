// name: expconn6.mo
// keywords:
// status: correct
//
// FAILREASON: Expandable connectors not handled yet.
//

expandable connector EC
  Real r;
end EC;

model M
  EC ec, ec2;
equation
  connect(ec.r, ec2.e);
end M;
