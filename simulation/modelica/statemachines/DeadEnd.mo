within;
model DeadEnd
  model State1
  end State1;
  State1 state1;
  model State2
  end State2;
  State2 state2;
equation
  transition(state1, state2, true, immediate=false);
  initialState(state1);
end DeadEnd;