// name: mod6.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  Real x = 1.0;
end A;

model B
  A a(x = 2.0);
end B;

// Result:
// class B
//   Real a.x = 2.0;
// end B;
// endResult
