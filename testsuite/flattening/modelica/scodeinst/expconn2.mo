// name: expconn2.mo
// keywords:
// status: correct
//
// FAILREASON: Expandable connectors not handled yet.
//

expandable connector EC
  C c;
end EC;

connector C
  Real e;
  flow Real f;
end C;

model M
  EC ec;
  C c;
equation
  connect(ec.c, c);
end M;
