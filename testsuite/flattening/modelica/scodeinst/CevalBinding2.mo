// name: CevalBinding2
// status: correct
//
// Simple test of component bindings.
//

model A
  constant Real x;
  constant Real y;
  constant Real z = x + y;
end A;

model CevalBinding2
  A a(x = 1.0, y = 2.0);
end CevalBinding2;

// Result:
// class CevalBinding2
//   constant Real a.x = 1.0;
//   constant Real a.y = 2.0;
//   constant Real a.z = 3.0;
// end CevalBinding2;
// endResult
