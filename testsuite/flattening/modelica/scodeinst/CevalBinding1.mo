// name: CevalBinding1
// status: correct
//
// Simple test of component bindings.
//

model CevalBinding1
  constant Real x = 1.0;
  constant Real y = 2.0;
  constant Real z = x + y;
end CevalBinding1;

// Result:
// class CevalBinding1
//   constant Real x = 1.0;
//   constant Real y = 2.0;
//   constant Real z = 3.0;
// end CevalBinding1;
// endResult
