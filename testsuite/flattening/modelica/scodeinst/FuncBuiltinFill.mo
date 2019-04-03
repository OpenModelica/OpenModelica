// name: FuncBuiltinFill
// keywords: fill
// status: correct
// cflags: -d=newInst
//
// Tests the builtin fill operator.
//

model FuncBuiltinFill
  Real x[4] = fill(1, 4);
  Real y[2, 4, 1] = fill(3.14, 2, 4, 1);
end FuncBuiltinFill;

// Result:
// class FuncBuiltinFill
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real y[1,1,1];
//   Real y[1,2,1];
//   Real y[1,3,1];
//   Real y[1,4,1];
//   Real y[2,1,1];
//   Real y[2,2,1];
//   Real y[2,3,1];
//   Real y[2,4,1];
// equation
//   x = {1.0, 1.0, 1.0, 1.0};
//   y = {{{3.14}, {3.14}, {3.14}, {3.14}}, {{3.14}, {3.14}, {3.14}, {3.14}}};
// end FuncBuiltinFill;
// endResult
