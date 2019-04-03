// name: FuncBuiltinSign
// keywords: sign
// status: correct
// cflags: -d=newInst
//
// Tests the builtin sign function.
//

model FuncBuiltinSign
  Integer r1 = sign(-6);
  Integer r2 = sign(4.0);
  Integer r3 = sign(r1 + r2);
end FuncBuiltinSign;

// Result:
// class FuncBuiltinSign
//   Integer r1 = -1;
//   Integer r2 = 1;
//   Integer r3 = sign(/*Real*/(r1 + r2));
// end FuncBuiltinSign;
// endResult
