// name: FuncBuiltinLinspace
// keywords: linspace
// status: correct
// cflags: -d=newInst
//
// Tests the builtin linspace operator.
//

model FuncBuiltinLinspace
  Real x[5] = linspace(2.0, 4.0, 5);
end FuncBuiltinLinspace;

// Result:
// class FuncBuiltinLinspace
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
// equation
//   x = linspace(2.0, 4.0, 5);
// end FuncBuiltinLinspace;
// endResult
