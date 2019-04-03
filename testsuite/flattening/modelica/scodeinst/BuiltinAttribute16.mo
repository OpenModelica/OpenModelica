// name: BuiltinAttribute16
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute16
  type MyReal = Real[3](each start = 1);
  MyReal x;
end BuiltinAttribute16;

// Result:
// class BuiltinAttribute16
//   Real x[1](start = 1.0);
//   Real x[2](start = 1.0);
//   Real x[3](start = 1.0);
// end BuiltinAttribute16;
// endResult
