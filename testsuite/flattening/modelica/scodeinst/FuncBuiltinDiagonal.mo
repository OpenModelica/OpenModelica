// name: FuncBuiltinDiagonal
// keywords: diagonal
// status: correct
// cflags: -d=newInst
//
// Tests the builtin diagonal operator.
//

model FuncBuiltinDiagonal
  Real x[3,3] = diagonal({1, 2, 3});
end FuncBuiltinDiagonal;

// Result:
// class FuncBuiltinDiagonal
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
//   Real x[3,1];
//   Real x[3,2];
//   Real x[3,3];
// equation
//   x = {{1.0, 0.0, 0.0}, {0.0, 2.0, 0.0}, {0.0, 0.0, 3.0}};
// end FuncBuiltinDiagonal;
// endResult
