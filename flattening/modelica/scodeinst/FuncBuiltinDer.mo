// name: FuncBuiltinDer
// keywords: der
// status: correct
// cflags: -d=newInst
//
// Tests the builtin der operator.
//

model FuncBuiltinDer
  Real x = time;
  Real y = der(x);
end FuncBuiltinDer;

// Result:
// class FuncBuiltinDer
//   Real x = time;
//   Real y = der(x);
// end FuncBuiltinDer;
// endResult
