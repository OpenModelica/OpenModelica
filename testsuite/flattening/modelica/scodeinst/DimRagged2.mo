// name: DimRagged2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  parameter Integer n;
  Real a[n];
end A;

model DimRagged2
  A arr[2](n = {3, 3});
end DimRagged2;

// Result:
// class DimRagged2
//   parameter Integer arr[1].n = 3;
//   Real arr[1].a[1];
//   Real arr[1].a[2];
//   Real arr[1].a[3];
//   parameter Integer arr[2].n = 3;
//   Real arr[2].a[1];
//   Real arr[2].a[2];
//   Real arr[2].a[3];
// end DimRagged2;
// endResult
