// name: FuncBuiltinDelay
// keywords: delay
// status: correct
// cflags: -d=newInst
//
// Tests the builtin delay operator.
//

model FuncBuiltinDelay
  Real x = time;
  Real y = delay(x, 1.0);
  Real z = delay(x, 2.0, 3.0);
end FuncBuiltinDelay;

// Result:
// class FuncBuiltinDelay
//   Real x = time;
//   Real y = delay(x, 1.0, 1.0);
//   Real z = delay(x, 2.0, 3.0);
// end FuncBuiltinDelay;
// endResult
