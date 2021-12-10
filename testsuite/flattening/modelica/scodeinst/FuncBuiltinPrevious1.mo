// name: FuncBuiltinPrevious1
// keywords: pre
// status: correct
// cflags: -d=newInst
//
// Tests the builtin previous operator.
//

model FuncBuiltinPrevious1
  Real x;
equation
  x = previous(x);
end FuncBuiltinPrevious1;

// Result:
// class FuncBuiltinPrevious1
//   Real x;
// equation
//   x = previous(x);
// end FuncBuiltinPrevious1;
// endResult
