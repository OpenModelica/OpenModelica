// name: mod10.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model A
  Real x;
end A;

model B
  A a(x);
end B;

// Result:
// class B
//   Real a.x;
// end B;
// endResult
