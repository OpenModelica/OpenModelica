// name: BreakModifier1
// keywords:
// status: correct
// cflags: -d=newInst
//

model BreakModifier1
  Real x = break;
end BreakModifier1;

// Result:
// class BreakModifier1
//   Real x;
// end BreakModifier1;
// endResult
