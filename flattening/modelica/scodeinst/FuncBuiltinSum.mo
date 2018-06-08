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
end FuncBuiltinSum;

// Result:
// class FuncBuiltinSum
//   Real r1 = 6.0;
//   Real r2 = 6.0;
//   Real r3 = 45.0;
//   Real r4 = 0.0;
// end FuncBuiltinSum;
// endResult
