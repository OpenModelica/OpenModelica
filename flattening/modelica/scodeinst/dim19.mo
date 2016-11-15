// name: dim19.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Bindings not subscripted.
//

model A
  parameter Integer n[3] = {1, 2, 3};
  parameter Integer m = n[2];
  Real x[m];
end A;
