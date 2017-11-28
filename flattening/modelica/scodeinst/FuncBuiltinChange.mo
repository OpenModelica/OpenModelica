// name: FuncBuiltinChange
// keywords: change
// status: correct
// cflags: -d=newInst
//
// Tests the builtin change operator.
//

model FuncBuiltinChange
  discrete Real x;
  Boolean y = change(x);
end FuncBuiltinChange;

// Result:
// class FuncBuiltinChange
//   discrete Real x;
//   Boolean y = change(x);
// end FuncBuiltinChange;
// endResult
