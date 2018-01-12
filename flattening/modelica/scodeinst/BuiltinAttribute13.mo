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
// class BuiltinAttribute12
//   Real x(start = 1.0);
// end BuiltinAttribute12;
// endResult
