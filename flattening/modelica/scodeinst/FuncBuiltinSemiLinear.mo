// name: FuncBuiltinSemiLinear
// keywords: semiLinear
// status: correct
// cflags: -d=newInst
//
// Tests the builtin semiLinear operator.
//

model FuncBuiltinSemiLinear
  Real x = time;
  Real r1 = semiLinear(x, 2, -3);
  Real r2 = semiLinear(x, r1, -r1);
end FuncBuiltinSemiLinear;

// Result:
// class FuncBuiltinSemiLinear
//   Real x = time;
//   Real r1 = semiLinear(x, 2.0, -3.0);
//   Real r2 = semiLinear(x, r1, -r1);
// end FuncBuiltinSemiLinear;
// endResult
