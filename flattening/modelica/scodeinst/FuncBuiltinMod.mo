// name: FuncBuiltinMod
// keywords: mod
// status: correct
// cflags: -d=newInst
//
// Tests the builtin mod function.
//

model FuncBuiltinMod
  Integer r1 = mod(7, 3);
  Real r2 = mod(8, 3.0);
  Real r3 = mod(12.0, 4.5);
end FuncBuiltinMod;

// Result:
// class FuncBuiltinMod
//   Integer r1 = mod(7, 3);
//   Real r2 = mod(8.0, 3.0);
//   Real r3 = mod(12.0, 4.5);
// end FuncBuiltinMod;
// endResult
