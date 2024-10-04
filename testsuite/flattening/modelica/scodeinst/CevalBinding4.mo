// name: CevalBinding4
// status: correct
//
// Simple test of component bindings.
//

model A
  constant Real x;
end A;

model CevalBinding4
  A a[3, 2](x = {{1.0, 2.0}, {3.0, 4.0}, {5.0, 6.0}});
  constant Real x[:] = a[1].x;
end CevalBinding4;

// Result:
// class CevalBinding4
//   constant Real a[1,1].x = 1.0;
//   constant Real a[1,2].x = 2.0;
//   constant Real a[2,1].x = 3.0;
//   constant Real a[2,2].x = 4.0;
//   constant Real a[3,1].x = 5.0;
//   constant Real a[3,2].x = 6.0;
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 2.0;
// end CevalBinding4;
// endResult
