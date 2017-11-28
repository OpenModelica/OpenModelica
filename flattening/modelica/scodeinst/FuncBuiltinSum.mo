// name: FuncBuiltinSum
// keywords: sum
// status: correct
// cflags: -d=newInst
//
// Tests the builtin sum operator.
//

model FuncBuiltinMax
  Real r1 = sum({1, 2, 3});
  Real r2 = sum({{1}, {2}, {3}});
  Real r3 = sum({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}});
  Real r4 = sum(1:0);
end FuncBuiltinMax;

// Result:
// class FuncBuiltinMax
//   Real r1 = /*Real*/(sum({1, 2, 3}));
//   Real r2 = /*Real*/(sum({{1}, {2}, {3}}));
//   Real r3 = /*Real*/(sum({{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}));
//   Real r4 = /*Real*/(sum(1:0));
// end FuncBuiltinMax;
// endResult
