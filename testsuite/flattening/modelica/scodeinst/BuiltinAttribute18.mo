// name: BuiltinAttribute18
// keywords:
// status: correct
// cflags: -d=newInst
//

model BuiltinAttribute18
  type Real4 = Real[4];

  type MyReal
    extends Real4;
  end MyReal;

  MyReal x(start = {1, 2, 3, 4});
end BuiltinAttribute18;

// Result:
// class BuiltinAttribute18
//   Real x[1](start = 1.0);
//   Real x[2](start = 2.0);
//   Real x[3](start = 3.0);
//   Real x[4](start = 4.0);
// end BuiltinAttribute18;
// endResult
