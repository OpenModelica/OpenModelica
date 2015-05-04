// name: TransitionTest
// keywords: state machines features
// status: correct

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
// class TransitionTest
//   output Real aState1.dummy;
//   output Real aState2.dummy;
// equation
//   transition(aState1, aState2, true, true, true, false, 1);
//   transition(aState1, aState2, true, false, true, false, 1);
//   transition(aState1, aState2, false, false, false, true, 10);
// end TransitionTest;
// endResult
