// name: BuiltinAttribute17
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute17
  type MyReal
    extends Real;
  end MyReal;

  type Real3 = Real[3](min = {1, 1, 1});
  Real3 x(start = {1, 2, 3});
end BuiltinAttribute17;

// Result:
// class BuiltinAttribute17
//   Real x[1](min = 1.0, start = 1.0);
//   Real x[2](min = 1.0, start = 2.0);
//   Real x[3](min = 1.0, start = 3.0);
// end BuiltinAttribute17;
// endResult
