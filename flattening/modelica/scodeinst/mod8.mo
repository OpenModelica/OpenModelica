// name: mod8.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  Real x;
end A;

model B
  Real y;
  A a(x = y);
end B;

// Result:
// class B
//   Real y;
//   Real a.x = y;
// end B;
// endResult
