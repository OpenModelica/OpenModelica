// name: TransitionTest
// keywords: state machines features
// status: wrong

model TransitionTest
  block AState
  output Real dummy;
  end AState;
  AState aState1;
  AState aState2;
equation
  transition(aState1, aState2, true);
  transition(aState1, aState2, true, false);
  transition(aState1, aState2, false, false, false, true, 10);
end TransitionTest;

// Result:
// endResult
