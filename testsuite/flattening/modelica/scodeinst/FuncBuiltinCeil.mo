// name: FuncBuiltinCeil
// keywords: ceil
// status: correct
// cflags: -d=newInst
//
// Tests the builtin ceil function.
//

model FuncBuiltinCeil
  Real r1 = ceil(4.25);
  Real r2 = ceil(-7.9);
  Real r3 = ceil(r1 / r2);
end FuncBuiltinCeil;

// Result:
// class FuncBuiltinCeil
//   Real r1 = 5.0;
//   Real r2 = -7.0;
//   Real r3 = ceil(r1 / r2);
// end FuncBuiltinCeil;
// endResult
