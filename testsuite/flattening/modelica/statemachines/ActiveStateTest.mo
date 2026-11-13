// name: ActiveTest
// keywords: state machines features
// status: correct

model ActiveStateTest
  block AState
  output Real dummy;
  end AState;
  AState aState;
  Boolean isActive;
equation
  isActive = activeState(aState);
end ActiveStateTest;

// Result:
// class ActiveStateTest
//   Real aState.dummy;
//   Boolean isActive;
// equation
//   isActive = activeState(aState);
// end ActiveStateTest;
// endResult
