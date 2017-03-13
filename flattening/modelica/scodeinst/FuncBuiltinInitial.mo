// name: FuncBuiltinInitial
// keywords: initial
// status: correct
// cflags: -d=newInst
//
// Tests the builtin initial operator.
//

model FuncBuiltinInitial
  Boolean s = initial();
end FuncBuiltinInitial;

// Result:
// class FuncBuiltinInitial
//   Boolean s = initial();
// end FuncBuiltinInitial;
// endResult
