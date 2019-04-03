// name: bindings4.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  Real x;
equation
  x = 2.0;
end A;

model B
  A a[3];
end B;

// Result:
// class B
//   Real a[1].x;
//   Real a[2].x;
//   Real a[3].x;
// equation
//   a[1].x = 2.0;
//   a[2].x = 2.0;
//   a[3].x = 2.0;
// end B;
// endResult
