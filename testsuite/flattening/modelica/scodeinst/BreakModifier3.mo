// name: BreakModifier3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x(start = 1.0, unit = "s", displayUnit="s");
end A;

model BreakModifier3
  A a(x(start = break, displayUnit = break));
end BreakModifier3;

// Result:
// class BreakModifier3
//   Real a.x(unit = "s");
// end BreakModifier3;
// endResult
