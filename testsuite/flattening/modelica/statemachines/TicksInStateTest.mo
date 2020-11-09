// name: TicksInStateTest
// keywords: state machines features
// status: correct
// cflags: -d=-newInst

model TicksInStateTest
  output Integer t;
equation
  t = ticksInState();
end TicksInStateTest;

// Result:
// class TicksInStateTest
//   output Integer t;
// equation
//   t = ticksInState();
// end TicksInStateTest;
// endResult
