// name: FuncBuiltinPrevious2
// keywords: pre
// status: correct
// cflags: -d=newInst
//
// Tests the builtin previous operator.
//

model FuncBuiltinPrevious2
  Real x[3];
equation
  x = previous(x);
end FuncBuiltinPrevious2;

// Result:
// class FuncBuiltinPrevious2
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x[1] = previous(x[1]);
//   x[2] = previous(x[2]);
//   x[3] = previous(x[3]);
// end FuncBuiltinPrevious2;
// endResult
