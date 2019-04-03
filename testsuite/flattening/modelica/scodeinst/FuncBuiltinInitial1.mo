// name: FuncBuiltinInitial1
// keywords: initial
// status: correct
// cflags: -d=newInst
//
// Tests the builtin initial operator.
//

model FuncBuiltinInitial1
  Boolean b = initial();
end FuncBuiltinInitial1;

// Result:
// class FuncBuiltinInitial1
//   Boolean b = initial();
// end FuncBuiltinInitial1;
// endResult
