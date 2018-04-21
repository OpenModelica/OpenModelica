// name: BuiltinAttribute13
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute13
  type MyReal = Real[3](start = {1.0, 2.0, 3.0});
  MyReal x;
end BuiltinAttribute13;

// Result:
// class BuiltinAttribute13
//   Real x[1](start = 1.0);
//   Real x[2](start = 2.0);
//   Real x[3](start = 3.0);
// end BuiltinAttribute13;
// endResult
