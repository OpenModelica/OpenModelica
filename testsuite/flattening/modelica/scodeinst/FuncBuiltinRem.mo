// name: FuncBuiltinRem
// keywords: rem
// status: correct
// cflags: -d=newInst
//
// Tests the builtin rem function.
//

model FuncBuiltinRem
  Real r1 = rem(5, 2);
  Real r2 = rem(5.0, 2);
  Real r3 = rem(8.0, 3.0);
end FuncBuiltinRem;

// Result:
// class FuncBuiltinRem
//   Real r1 = 1.0;
//   Real r2 = 1.0;
//   Real r3 = 2.0;
// end FuncBuiltinRem;
// endResult
