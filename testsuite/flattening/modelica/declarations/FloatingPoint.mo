// name: FloatingPoint
// keywords: real
// status: correct
// cflags: -d=-newInst
//
// Tests the different ways floating point numbers may be declared
//

model FloatingPoint
  constant Real r1 = 1.7976931348623157E308;
  constant Real r2 = 2.2250738585072014E-308;
  constant Real r3 = 22.5;
  constant Real r4 = 3.141592653589793;
  constant Real r5 = 1.2E-35;
  constant Real r6 = 13.;
  constant Real r7 = 13E0;
  constant Real r8 = 1.3e1;
  constant Real r9 = .13E2;
  constant Real r10 = 2;
  Real x;
equation
  x = 2e0;
end FloatingPoint;

// Result:
// class FloatingPoint
//   constant Real r1 = 1.797693134862316e+308;
//   constant Real r2 = 2.225073858507201e-308;
//   constant Real r3 = 22.5;
//   constant Real r4 = 3.141592653589793;
//   constant Real r5 = 1.2e-35;
//   constant Real r6 = 13.0;
//   constant Real r7 = 13.0;
//   constant Real r8 = 13.0;
//   constant Real r9 = 13.0;
//   constant Real r10 = 2.0;
//   Real x;
// equation
//   x = 2.0;
// end FloatingPoint;
// endResult
