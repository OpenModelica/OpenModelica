// name: conn12.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Expandable connector checks are not perfect yet.
//

connector C
  input Real ir;
end C;

expandable connector EC end EC;

model M1
  C c1;
  EC ec;
equation
  connect(c1.ir, ec.ir);
end M1;

model M2
  C c2;
  EC ec;
equation
  connect(c2.ir, ec.ir);
end M2;

model M3
  EC ec;
  M1 m1;
  M2 m2;
equation
  connect(m1.ec, ec);
  connect(m2.ec, ec);
end M3;
