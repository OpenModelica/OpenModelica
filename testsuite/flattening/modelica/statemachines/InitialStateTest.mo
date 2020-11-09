// name: InitialStateTest
// keywords: state machines features
// status: wrong
// cflags: -d=-newInst

model InitialStateTest
  block AState
  output Real dummy;
  end AState;
  AState aState;
equation
  initialState(aState);
end InitialStateTest;

// Result:
// endResult
