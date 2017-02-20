model AccessFromOutside "Access previous value from local state variable from outside"
  output Real y;
  model State1
  output Integer i(start=2);
  equation
    i = previous(i) + 2;
  end State1;
  State1 state1;
  model State2
  end State2;
  State2 state2;
equation
  initialState(state1);
  transition(
    state1,
    state2,
    state1.i > 10,
    immediate=false);
  transition(
    state2,
    state1,
    true,
    immediate=false);
  y = previous(state1.i);
end AccessFromOutside;
