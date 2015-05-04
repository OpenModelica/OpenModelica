// name: InitialStateTest
// keywords: state machines features
// status: correct

model InitialStateTest
  block AState
  output Real dummy;
  end AState;
  AState aState;
equation
  initialState(aState);
end InitialStateTest;

// Result:
// class InitialStateTest
//   output Real aState.dummy;
// equation
//   initialState(aState);
// end InitialStateTest;
// endResult
