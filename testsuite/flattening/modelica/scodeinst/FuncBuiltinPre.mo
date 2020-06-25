// name: FuncBuiltinPre
// keywords: pre
// status: correct
// cflags: -d=newInst
//
// Tests the builtin pre operator.
//

model FuncBuiltinPre
  Real x = 1.0;
  Real y = pre(x);
  Integer i = 1;
  Real z = pre(i);
end FuncBuiltinPre;

// Result:
// class FuncBuiltinPre
//   Real x = 1.0;
//   Real y = pre(x);
//   Integer i = 1;
//   Real z = /*Real*/(pre(i));
// end FuncBuiltinPre;
// endResult
