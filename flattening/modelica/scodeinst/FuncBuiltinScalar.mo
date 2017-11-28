// name: FuncBuiltinScalar
// keywords: scalar
// status: correct
// cflags: -d=newInst
//
// Tests the builtin scalar operator.
//

model FuncBuiltinScalar
  Real r1 = scalar({{1}});
  Real r2 = scalar(4);
  Real r3 = scalar({{{{5}}}});
end FuncBuiltinScalar;

// Result:
// class FuncBuiltinScalar
//   Real r1 = /*Real*/(scalar({{1}}));
//   Real r2 = /*Real*/(scalar(4));
//   Real r3 = /*Real*/(scalar({{{{5}}}}));
// end FuncBuiltinScalar;
// endResult
