// name: BuiltinAttribute12
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute12
  type MyReal = Real(start = 1.0);
  type MyReal2 = MyReal;
  MyReal x;
end BuiltinAttribute12;

// Result:
// class BuiltinAttribute12
//   Real x(start = 1.0);
// end BuiltinAttribute12;
// endResult
