// name: Prefix1
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x;
  Real y = x;
equation
  x = y;
end A;

model Prefix1
  A a[3];
end Prefix1;

// Result:
// class Prefix1
//   Real a[1].x;
//   Real a[1].y = a[1].x;
//   Real a[2].x;
//   Real a[2].y = a[2].x;
//   Real a[3].x;
//   Real a[3].y = a[3].x;
// equation
//   a[1].x = a[1].y;
//   a[2].x = a[2].y;
//   a[3].x = a[3].y;
// end Prefix1;
// endResult
