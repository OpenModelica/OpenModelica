// name: BuiltinAttribute14
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute14
  Real x[3](start = {1, 2, 3}, each nominal = 1);
end BuiltinAttribute14;

// Result:
// class BuiltinAttribute14
//   Real x[1](start = 1.0, nominal = 1.0);
//   Real x[2](start = 2.0, nominal = 1.0);
//   Real x[3](start = 3.0, nominal = 1.0);
// end BuiltinAttribute14;
// endResult
