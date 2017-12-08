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
  Integer i;
  Real z = pre(i);
end FuncBuiltinPre;

// Result:
// class FuncBuiltinPre
//   discrete Real x;
//   Real y = pre(x);
//   Integer i;
//   Real z = /*Real*/(pre(i));
// end FuncBuiltinPre;
// endResult
