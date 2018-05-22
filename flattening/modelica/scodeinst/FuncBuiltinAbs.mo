// name: FuncBuiltinAbs
// keywords: abs
// status: correct
// cflags: -d=newInst
//
// Tests the builtin abs function.
//

model FuncBuiltinAbs
  Real r1 = abs(-2.0);
  Integer r2 = abs(3);
  Real r3 = abs(r1 - r2);
end FuncBuiltinAbs;

// Result:
// class FuncBuiltinAbs
//   Real r1 = 2.0;
//   Integer r2 = 3;
//   Real r3 = abs(r1 - /*Real*/(r2));
// end FuncBuiltinAbs;
// endResult
