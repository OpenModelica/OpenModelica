// name: FuncBuiltin
// keywords:
// status: correct
// cflags: -d=newInst
//
// Tests some builtin functions.
//

model FuncBuiltin
  Real r1 = abs(-2.0);
  Integer r2 = abs(3);
end FuncBuiltin;

// Result:
// class FuncBuiltin
//   Real r1 = abs(-2.0);
//   Integer r2 = abs(3);
// end FuncBuiltin;
// endResult
