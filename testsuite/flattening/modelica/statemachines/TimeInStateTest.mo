// name: TimeInStateTest
// keywords: state machines features
// status: correct
// cflags: -d=-newInst

model TimeInStateTest
  output Real t;
equation
  t = timeInState();
end TimeInStateTest;

// Result:
// class TimeInStateTest
//   output Real t;
// equation
//   t = timeInState();
// end TimeInStateTest;
// endResult
