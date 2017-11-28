// name: FuncBuiltinSmooth
// keywords: smooth
// status: correct
// cflags: -d=newInst
//
// Tests the builtin smooth operator.
//

model FuncBuiltinSmooth
  parameter Integer k = 1;
  Real x = time;
  Real y = smooth(k, x);
  Real z = smooth(2, {x, x});
end FuncBuiltinSmooth;

// Result:
// class FuncBuiltinSmooth
//   parameter Integer k = 1;
//   Real x = time;
//   Real y = smooth(k, x);
//   Real z = smooth(2, {x, x});
// end FuncBuiltinSmooth;
// endResult
