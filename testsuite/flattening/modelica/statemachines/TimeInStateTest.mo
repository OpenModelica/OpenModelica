// name: TimeInStateTest
// keywords: state machines features
// status: correct

model TimeInStateTest
  output Real t;
equation
  t = timeInState();
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end TimeInStateTest;

// Result:
// class TimeInStateTest
//   output Real t;
// equation
//   t = timeInState();
// end TimeInStateTest;
// endResult
