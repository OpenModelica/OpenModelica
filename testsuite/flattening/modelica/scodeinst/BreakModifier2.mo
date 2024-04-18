// name: BreakModifier2
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x = 1;
  Real y = 2;
  Real z = 3;
  Real w = 4;
end A;

model BreakModifier2
  A a(x = break, y = 5, z = break);
end BreakModifier2;

// Result:
// class BreakModifier2
//   Real a.x;
//   Real a.y = 5.0;
//   Real a.z;
//   Real a.w = 4.0;
// end BreakModifier2;
// endResult
