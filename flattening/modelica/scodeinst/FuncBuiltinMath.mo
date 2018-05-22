// name: FuncBuiltinMath
// keywords: 
// status: correct
// cflags: -d=newInst
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
//   Real r3 = 1.557407724654902;
//   Real r4 = asin(r1);
//   Real r5 = acos(r2 * r3);
//   Real r6 = 1.10714871779409;
//   Real r7 = 0.9827937232473291;
//   Real r8 = 27.28991719712775;
//   Real r9 = 4872401723.124452;
//   Real r10 = 0.9950547536867305;
//   Real r11 = 90.01713130052181;
//   Real r12 = 6.931471805599453;
//   Real r13 = 2.397940008672037;
// end FuncBuiltinMath;
// endResult
