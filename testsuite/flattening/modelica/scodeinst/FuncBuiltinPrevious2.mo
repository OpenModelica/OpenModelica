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
//   x = array(previous(x[$i1]) for $i1 in 1:3);
// end FuncBuiltinPrevious2;
// endResult
