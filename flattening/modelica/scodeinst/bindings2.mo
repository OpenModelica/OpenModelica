// name: bindings2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  Real x;
end A;

model B
  A a[3](x = {1, 2, 3});
end B;

// Result:
// class B
//   Real a[1].x = 1.0;
//   Real a[2].x = 2.0;
//   Real a[3].x = 3.0;
// end B;
// endResult
