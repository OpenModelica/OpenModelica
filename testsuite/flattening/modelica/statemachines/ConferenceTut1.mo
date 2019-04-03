// name: ConferenceTut1
// keywords: state machines features
// status: correct

model ConferenceTut1
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
  transition(
    state2,
    state1,
    i < 1,
    immediate=false);
end ConferenceTut1;


// Result:
// class ConferenceTut1
//   Integer i(start = 0);
// stateMachine state1
//   state state1
//       output Integer state1.i;
//     equation
//       state1.i = 2 + previous(i);
//   end state1;
//
//   state state2
//       output Integer state2.i;
//     equation
//       state2.i = -1 + previous(i);
//   end state2;
//   equation
//     initialState(state1);
//     transition(state1, state2, i > 10, false, true, false, 1);
//     transition(state2, state1, i < 1, false, true, false, 1);
// end state1;
// equation
//   i = if activeState(state1) then state1.i else if activeState(state2) then state2.i else previous(i);
// end ConferenceTut1;
// endResult
