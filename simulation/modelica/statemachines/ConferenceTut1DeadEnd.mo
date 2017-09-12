model ConferenceTut1DeadEnd "ConferenceTut1 example but without returning transition"
  inner Integer i(start=0);
  model State1
  outer output Integer i;
  equation
    i = previous(i) + 2;
  end State1;
  State1 state1;
  model State2
  outer output Integer i;
  equation
    i = previous(i) - 1;
  end State2;
  State2 state2;
equation
  initialState(state1);
  transition(
    state1,
    state2,
    i > 10,
    immediate=false);
end ConferenceTut1DeadEnd;
