// name: TicksInStateTest
// keywords: state machines features
// status: correct

model TicksInStateTest
  output Integer t;
equation
  t = ticksInState();
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end TicksInStateTest;

// Result:
// class TicksInStateTest
//   output Integer t;
// equation
//   t = ticksInState();
// end TicksInStateTest;
// endResult
