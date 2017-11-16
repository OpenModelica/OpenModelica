// name: FuncBuiltinPre
// keywords: pre
// status: correct
// cflags: -d=newInst
//
// Tests the builtin pre operator.
//

model FuncBuiltinPre
  discrete Real x;
  Real y = pre(x);
end FuncBuiltinPre;

// Result:
// class FuncBuiltinPre
//   discrete Real x;
//   Real y = pre(x);
// end FuncBuiltinPre;
// endResult
