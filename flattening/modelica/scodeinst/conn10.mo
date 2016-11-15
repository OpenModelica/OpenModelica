// name: conn10.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Connects not handled yet.
//

connector C
  Real e;
  flow Real f;
end C;

model A
  Real x[3, 2], y[3, 2];
equation
  //connect(x, y);
end A;

model B
  A a[3];
equation
  connect(a.x, a.y);
end B;
