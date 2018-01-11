// name: BuiltinAttribute11
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute11
  type MyReal = Real(start = 1.0);
  MyReal x[3];
end BuiltinAttribute11;

// Result:
// class BuiltinAttribute11
//   Real x[1](start = 1.0);
//   Real x[2](start = 1.0);
//   Real x[3](start = 1.0);
// end BuiltinAttribute11;
// endResult
