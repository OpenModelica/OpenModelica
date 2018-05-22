// name: FuncBuiltinSize
// keywords: size
// status: correct
// cflags: -d=newInst
//
// Tests the builtin size operator.
//

model FuncBuiltinSize
  Real x[1, 2, 3];
  Integer i1 = size(x, 1);
  Integer i2 = size(x, 2);
  Integer i3 = size(x, 3);
  Integer i4 = size({1, 2, 3}, 1);
  Integer i5[3] = size(x);
end FuncBuiltinSize;

// Result:
// class FuncBuiltinSize
//   Real x[1,1,1];
//   Real x[1,1,2];
//   Real x[1,1,3];
//   Real x[1,2,1];
//   Real x[1,2,2];
//   Real x[1,2,3];
//   Integer i1 = 1;
//   Integer i2 = 2;
//   Integer i3 = 3;
//   Integer i4 = 3;
//   Integer i5[1];
//   Integer i5[2];
//   Integer i5[3];
// equation
//   i5 = {1, 2, 3};
// end FuncBuiltinSize;
// endResult
