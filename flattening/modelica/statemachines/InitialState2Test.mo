// name: InitialState2Test
// keywords: state machines features
// status: correct

model InitialState2Test
  block AState
  end AState;
  AState aState;
equation
  initialState(aState);
end InitialState2Test;

// Result:
// class InitialState2Test
// equation
//   initialState(aState);
// end InitialState2Test;
// endResult
