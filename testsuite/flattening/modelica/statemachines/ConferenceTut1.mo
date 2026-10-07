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
//   discrete Integer state2.i(start = 0, fixed = true);
//   discrete Integer state1.i(start = 0, fixed = true);
//   discrete Boolean smOf.state1.stateMachineInFinalState;
//   discrete Boolean smOf.state1.finalStates[2];
//   discrete Boolean smOf.state1.nextResetStates[2](start = false, fixed = true);
//   discrete Boolean smOf.state1.activeResetStates[2];
//   discrete Boolean smOf.state1.finalStates[1];
//   discrete Boolean smOf.state1.nextResetStates[1](start = false, fixed = true);
//   discrete Boolean smOf.state1.activeResetStates[1];
//   discrete Boolean smOf.state1.nextReset(start = false, fixed = true);
//   discrete Integer smOf.state1.nextState(start = 0, fixed = true);
//   discrete Boolean smOf.state1.activeReset;
//   discrete Integer smOf.state1.activeState;
//   discrete Integer smOf.state1.fired;
//   discrete Boolean smOf.state1.selectedReset;
//   discrete Integer smOf.state1.selectedState;
//   discrete Boolean smOf.state1.reset;
//   discrete Boolean smOf.state1.active;
//   discrete Boolean smOf.state1.c[2];
//   discrete Boolean smOf.state1.cImmediate[2](start = false, fixed = true);
//   discrete Boolean smOf.state1.c[1];
//   discrete Boolean smOf.state1.cImmediate[1](start = false, fixed = true);
//   final parameter Integer smOf.state1.tPriority[2] = 1;
//   final parameter Boolean smOf.state1.tSynchronize[2] = false;
//   final parameter Boolean smOf.state1.tReset[2] = true;
//   final parameter Boolean smOf.state1.tImmediate[2] = false;
//   final parameter Integer smOf.state1.tTo[2] = 2;
//   final parameter Integer smOf.state1.tFrom[2] = 1;
//   final parameter Integer smOf.state1.tPriority[1] = 1;
//   final parameter Boolean smOf.state1.tSynchronize[1] = false;
//   final parameter Boolean smOf.state1.tReset[1] = true;
//   final parameter Boolean smOf.state1.tImmediate[1] = false;
//   final parameter Integer smOf.state1.tTo[1] = 1;
//   final parameter Integer smOf.state1.tFrom[1] = 2;
//   final parameter Integer smOf.state1.nState = 2;
//   Real state2.$timeEnteredState(start = 0.0, fixed = true);
//   Real state2.$timeInState(start = 0.0, fixed = true);
//   discrete Integer state2.$ticksInState(start = 0, fixed = true);
//   discrete Boolean state2.active(start = false, fixed = true);
//   Real state1.$timeEnteredState(start = 0.0, fixed = true);
//   Real state1.$timeInState(start = 0.0, fixed = true);
//   discrete Integer state1.$ticksInState(start = 0, fixed = true);
//   discrete Boolean state1.active(start = false, fixed = true);
//   discrete Boolean smOf.state1.init(start = true, fixed = true);
//   Integer i(start = 0);
// equation
//   i = if state1.active then state1.i else if state2.active then state2.i else previous(i);
//   state2.i = if state2.active then previous(i) - 1 else previous(state2.i);
//   state1.i = if state1.active then previous(i) + 2 else previous(state1.i);
//   smOf.state1.stateMachineInFinalState = smOf.state1.finalStates[smOf.state1.activeState];
//   smOf.state1.finalStates[2] = max({if smOf.state1.tFrom[1] == 2 then 1 else 0, if smOf.state1.tFrom[2] == 2 then 1 else 0}) == 0;
//   smOf.state1.finalStates[1] = max({if smOf.state1.tFrom[1] == 1 then 1 else 0, if smOf.state1.tFrom[2] == 1 then 1 else 0}) == 0;
//   smOf.state1.nextResetStates[2] = if smOf.state1.active then if smOf.state1.activeState == 2 then false else smOf.state1.activeResetStates[2] else previous(smOf.state1.nextResetStates[2]);
//   smOf.state1.nextResetStates[1] = if smOf.state1.active then if smOf.state1.activeState == 1 then false else smOf.state1.activeResetStates[1] else previous(smOf.state1.nextResetStates[1]);
//   smOf.state1.activeResetStates[2] = if smOf.state1.reset then true else previous(smOf.state1.nextResetStates[2]);
//   smOf.state1.activeResetStates[1] = if smOf.state1.reset then true else previous(smOf.state1.nextResetStates[1]);
//   smOf.state1.nextReset = if smOf.state1.active then false else previous(smOf.state1.nextReset);
//   smOf.state1.nextState = if smOf.state1.active then smOf.state1.activeState else previous(smOf.state1.nextState);
//   smOf.state1.activeReset = if smOf.state1.reset then true else if smOf.state1.fired > 0 then smOf.state1.tReset[smOf.state1.fired] else smOf.state1.selectedReset;
//   smOf.state1.activeState = if smOf.state1.reset then 1 else if smOf.state1.fired > 0 then smOf.state1.tTo[smOf.state1.fired] else smOf.state1.selectedState;
//   smOf.state1.fired = max({if if smOf.state1.tFrom[1] == smOf.state1.selectedState then smOf.state1.c[1] else false then 1 else 0, if if smOf.state1.tFrom[2] == smOf.state1.selectedState then smOf.state1.c[2] else false then 2 else 0});
//   smOf.state1.selectedReset = if smOf.state1.reset then true else previous(smOf.state1.nextReset);
//   smOf.state1.selectedState = if smOf.state1.reset then 1 else previous(smOf.state1.nextState);
//   smOf.state1.c[2] = previous(smOf.state1.cImmediate[2]);
//   smOf.state1.cImmediate[2] = i > 10;
//   smOf.state1.c[1] = previous(smOf.state1.cImmediate[1]);
//   smOf.state1.cImmediate[1] = i < 1;
//   state2.$timeEnteredState = if previous(state2.active) == false and state2.active == true then sample(time, Clock()) else previous(state2.$timeEnteredState);
//   state2.$timeInState = if state2.active then sample(time, Clock()) - state2.$timeEnteredState else 0.0;
//   state2.$ticksInState = if not state2.active then 0 else previous(state2.$ticksInState) + 1;
//   state2.active = smOf.state1.active and smOf.state1.activeState == 2;
//   state1.$timeEnteredState = if previous(state1.active) == false and state1.active == true then sample(time, Clock()) else previous(state1.$timeEnteredState);
//   state1.$timeInState = if state1.active then sample(time, Clock()) - state1.$timeEnteredState else 0.0;
//   state1.$ticksInState = if not state1.active then 0 else previous(state1.$ticksInState) + 1;
//   state1.active = smOf.state1.active and smOf.state1.activeState == 1;
//   smOf.state1.active = true;
//   smOf.state1.reset = previous(smOf.state1.init);
//   smOf.state1.init = false;
// end ConferenceTut1;
// endResult
