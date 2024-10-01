// name: CevalBinding3
// status: correct
//
// Simple test of component bindings.
//

model A
  constant Real x;
  constant Real y;
  constant Real z = x + y;
end A;

model CevalBinding3
  A a[3](x = {1.0, 2.0, 3.0}, y = {4.0, 5.0, 6.0});
end CevalBinding3;

// Result:
// class CevalBinding3
//   constant Real a[1].x = 1.0;
//   constant Real a[1].y = 4.0;
//   constant Real a[1].z = 5.0;
//   constant Real a[2].x = 2.0;
//   constant Real a[2].y = 5.0;
//   constant Real a[2].z = 7.0;
//   constant Real a[3].x = 3.0;
//   constant Real a[3].y = 6.0;
//   constant Real a[3].z = 9.0;
// end CevalBinding3;
// endResult
