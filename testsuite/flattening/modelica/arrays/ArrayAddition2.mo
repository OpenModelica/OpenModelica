// name: ArrayAddition2
// status: correct

model ArrayAddition2
  Real Stock1[1,1,1](each fixed = false, each start = 0.0);
  Real Stock2[1,1,1](each fixed = false, each start = 0.0);
  Real Valve1[1,1,1] = fill(1, 1, 1, 1);
  Real Valve2[1,1,1] = fill(1, 1, 1, 1);
equation
  der(Stock1) = Valve1 + Valve2;
  der(Stock2) = Valve1 - Valve2;
end ArrayAddition2;

// Result:
// class ArrayAddition2
//   Real Stock1[1,1,1](start = 0.0, fixed = false);
//   Real Stock2[1,1,1](start = 0.0, fixed = false);
//   Real Valve1[1,1,1];
//   Real Valve2[1,1,1];
// equation
//   Valve1 = {{{1.0}}};
//   Valve2 = {{{1.0}}};
//   der(Stock1[1,1,1]) = Valve1[1,1,1] + Valve2[1,1,1];
//   der(Stock2[1,1,1]) = Valve1[1,1,1] - Valve2[1,1,1];
// end ArrayAddition2;
// endResult
