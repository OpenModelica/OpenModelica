model SMMin "Minimal example with two states and no equations within the states"
  model State1
  end State1;
  model State2
  end State2;

  State2 state2;
  State1 state1;
equation
  initialState(state1);
  transition(
    state1,
    state2,
    true,
    immediate=false);
  transition(
    state2,
    state1,
    true,
    immediate=false);
end SMMin;
