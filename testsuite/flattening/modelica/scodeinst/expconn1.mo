// name: expconn1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Expandable connectors not handled yet.
//

expandable connector EC
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
