// name: conn11.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Connect equation not expanded.
//

model IndexConnect
  connector A
    Real e;
  end A;

  constant Integer n=5;
  A a[n];
equation
  a[1].e = 1;
  connect(a[1:n-1],a[2:n]);
end IndexConnect;
