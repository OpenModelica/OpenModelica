// name: DimUnknown8
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  Real x[:];
  Real y[size(x, 1)];
end A;

model DimUnknown8
  A a[2](each x = {1, 2, 3});
end DimUnknown8;

// Result:
// class DimUnknown8
//   Real a[1].x[1];
//   Real a[1].x[2];
//   Real a[1].x[3];
//   Real a[1].y[1];
//   Real a[1].y[2];
//   Real a[1].y[3];
//   Real a[2].x[1];
//   Real a[2].x[2];
//   Real a[2].x[3];
//   Real a[2].y[1];
//   Real a[2].y[2];
//   Real a[2].y[3];
// equation
//   a[1].x = {1.0, 2.0, 3.0};
//   a[2].x = {1.0, 2.0, 3.0};
// end DimUnknown8;
// endResult
