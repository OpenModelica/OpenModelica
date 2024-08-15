// name: FuncBuiltinSum
// keywords: sum
// status: correct
// cflags: -d=newInst
//
// Tests the builtin sum operator.
//

model FuncBuiltinSum
  Real r1 = sum({1, 2, 3});
  Real r2 = sum({{1}, {2}, {3}});
  Real r3 = sum({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
  Real r4 = sum(1:0);
  Real x[3];
  Real r5 = sum(x);
end FuncBuiltinSum;

// Result:
// class FuncBuiltinSum
//   Real r1 = 6.0;
//   Real r2 = 6.0;
//   Real r3 = 45.0;
//   Real r4 = 0.0;
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real r5 = x[1] + x[2] + x[3];
// end FuncBuiltinSum;
// endResult
