// name: FuncBuiltinMath
// keywords: 
// status: correct
//
// Tests the builtin math functions.
//

model FuncBuiltinMath
  Real r1 = sin(4);
  Real r2 = cos(-2);
  Real r3 = tan(1);
  Real r4 = asin(r1);
  Real r5 = acos(r2 * r3);
  Real r6 = atan(2);
  Real r7 = atan2(3, 2.0);
  Real r8 = sinh(4.0);
  Real r9 = cosh(23);
  Real r10 = tanh(3);
  Real r11 = exp(4.5);
  Real r12 = log(1024);
  Real r13 = log10(250);
end FuncBuiltinMath;

// Result:
// class FuncBuiltinMath
//   Real r1 = -0.7568024953079282;
//   Real r2 = -0.4161468365471424;
//   Real r3 = 1.5574077246549023;
//   Real r4 = asin(r1);
//   Real r5 = acos(r2 * r3);
//   Real r6 = 1.1071487177940904;
//   Real r7 = 0.982793723247329;
//   Real r8 = 27.28991719712775;
//   Real r9 = 4.872401723124452e9;
//   Real r10 = 0.9950547536867305;
//   Real r11 = 90.01713130052181;
//   Real r12 = 6.931471805599453;
//   Real r13 = 2.3979400086720375;
// end FuncBuiltinMath;
// endResult
