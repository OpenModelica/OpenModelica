// name: FuncBuiltinInteger
// keywords: integer
// status: correct
// cflags: -d=newInst
//
// Tests the builtin integer function.
//

model FuncBuiltinInteger
  Integer r1 = integer(4.25);
  Integer r2 = integer(-9.9);
  Integer r3 = integer(r1 / r2);
end FuncBuiltinInteger;

// Result:
// class FuncBuiltinInteger
//   Integer r1 = 4;
//   Integer r2 = -10;
//   Integer r3 = integer(/*Real*/(r1) / /*Real*/(r2));
// end FuncBuiltinInteger;
// endResult
