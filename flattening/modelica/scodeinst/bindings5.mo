// name: bindings5.mo
// keywords:
// status: correct
// cflags:   +d=newInst
//

model N
  Real r;
end N;

model M
  N n(each r = 1.0);
end M;

// Result:
// class M
//   Real n.r = 1.0;
// end M;
// endResult
