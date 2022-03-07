// name: FuncBuiltinHold1
// keywords:
// status: correct
// cflags: -d=newInst
//

model FuncBuiltinHold1
  Real x, y;
equation
  y = hold(x);
end FuncBuiltinHold1;

// Result:
// class FuncBuiltinHold1
//   Real x;
//   Real y;
// equation
//   y = hold(x);
// end FuncBuiltinHold1;
// endResult
