// name: FuncBuiltinPrevious1
// keywords: pre
// status: correct
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
