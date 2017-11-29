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
  Boolean b;
  Boolean z = change(b);
end FuncBuiltinChange;

// Result:
// class FuncBuiltinChange
//   discrete Real x;
//   Boolean y = change(x);
//   Boolean b;
//   Boolean z = change(b);
// end FuncBuiltinChange;
// endResult
