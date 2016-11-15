// name: dim17.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: All array dimensions of y are instantiated when infering the
// dimensions of x, which is not strictly needed.
//

model A
  Real x[3, :] = y * 4;
  Real y[:, 4] = x;
end A;
