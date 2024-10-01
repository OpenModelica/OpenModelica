// name: InitialState2Test
// keywords: state machines features
// status: wrong

model InitialState2Test
  block AState
  end AState;
  AState aState;
equation
  initialState(aState);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end InitialState2Test;

// Result:
// endResult
