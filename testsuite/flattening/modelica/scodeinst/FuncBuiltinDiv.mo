// name: FuncBuiltinDiv
// keywords: div
// status: correct
// cflags: -d=newInst
//
// Tests the builtin div function.
//

model FuncBuiltinDiv
  Integer r1 = div(6, 2);
  Real r2 = div(8, 1.5);
  Real r3 = div(25.0, 4.0);
end FuncBuiltinDiv;

// Result:
// class FuncBuiltinDiv
//   Integer r1 = 3;
//   Real r2 = 5.0;
//   Real r3 = 6.0;
// end FuncBuiltinDiv;
// endResult
