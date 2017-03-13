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
//   Real r1 = sin(4.0);
//   Real r2 = cos(-2.0);
//   Real r3 = tan(1.0);
//   Real r4 = asin(r1);
//   Real r5 = acos(r2 * r3);
//   Real r6 = atan(2.0);
//   Real r7 = atan2(3.0, 2.0);
//   Real r8 = sinh(4.0);
//   Real r9 = cosh(23.0);
//   Real r10 = tanh(3.0);
//   Real r11 = exp(4.5);
//   Real r12 = log(1024.0);
//   Real r13 = log10(250.0);
// end FuncBuiltinMath;
// endResult
