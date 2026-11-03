// name: TicksInStateTest
// keywords: state machines features
// status: correct

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
