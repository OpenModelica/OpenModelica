// name: expconn3.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Expandable connectors not handled yet.
//

expandable connector EC
end EC;

connector RealInput = input Real;

model M
  EC ec;
  RealInput ri;
equation
  connect(ec.ri, ri);
end M;
