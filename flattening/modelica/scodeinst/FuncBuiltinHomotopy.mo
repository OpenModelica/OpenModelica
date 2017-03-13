// name: FuncBuiltinHomotopy
// keywords: homotopy
// status: correct
// cflags: -d=newInst
//
// Tests the builtin homotopy operator.
//

model FuncBuiltinHomotopy
  Real x = 1.0;
  Real y = time;
  Real r1 = homotopy(x, y);
  Real r2 = homotopy(actual = x, simplified = y);
  Real r3 = homotopy(x, simplified = y);
end FuncBuiltinHomotopy;

// Result:
// class FuncBuiltinHomotopy
//   Real x = 1.0;
//   Real y = time;
//   Real r1 = homotopy(x, y);
//   Real r2 = homotopy(x, y);
//   Real r3 = homotopy(x, y);
// end FuncBuiltinHomotopy;
// endResult
