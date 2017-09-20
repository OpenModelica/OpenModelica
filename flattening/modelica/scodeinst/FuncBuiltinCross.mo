// name: FuncBuiltinCross
// keywords: cross
// status: correct
// cflags: -d=newInst
//
// Tests the builtin cross operator.
//

model FuncBuiltinCross
  Real x[3] = cross({1, 2, 3}, {4, 5, 6});
end FuncBuiltinCross;

// Result:
// class FuncBuiltinCross
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = cross({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0});
// end FuncBuiltinCross;
// endResult
