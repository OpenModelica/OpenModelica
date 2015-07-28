// name: InitialState2Test
// keywords: state machines features
// status: wrong

model InitialState2Test
  block AState
  end AState;
  AState aState;
equation
  initialState(aState);
end InitialState2Test;

// Result:
// endResult
