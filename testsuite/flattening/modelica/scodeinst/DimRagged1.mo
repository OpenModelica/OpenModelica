// name: DimRagged1
// keywords:
// status: correct
//

model A
  parameter Integer n;
  Real a[n];
end A;

model DimRagged1
  A arr[2](n = {2, 3});
end DimRagged1;

// Result:
// class DimRagged1
//   final parameter Integer arr[1].n = 2;
//   Real arr[1].a[1];
//   Real arr[1].a[2];
//   final parameter Integer arr[2].n = 3;
//   Real arr[2].a[1];
//   Real arr[2].a[2];
//   Real arr[2].a[3];
// end DimRagged1;
// endResult
