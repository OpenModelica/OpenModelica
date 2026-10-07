// name: HierarchicalAndParallelStateMachine
// keywords: state machines features
// status: correct

block HierarchicalAndParallelStateMachine
  "Example from the MLS 3.3, Section 17.3.7"
  inner Integer v(start=0);

  State1 state1;
  State2 state2;
equation
  initialState(state1);
  transition(state1,state2,activeState(state1.stateD) and activeState(state1.stateY), immediate=false);
  transition(state2,state1,v >= 20, immediate=false);

public
  block State1
    inner Integer count(start=0);
    inner outer output Integer v;

    block StateA
      outer output Integer v;
    equation
      v = previous(v) + 2;
    end StateA;
    StateA stateA;

    block StateB
      outer output Integer v;
    equation
      v = previous(v) - 1;
    end StateB;
    StateB stateB;

    block StateC
      outer output Integer count;
    equation
      count = previous(count) + 1;
    end StateC;
    StateC stateC;

    block StateD
    end StateD;
    StateD stateD;

  equation
    initialState(stateA);
    transition(stateA, stateB, v >= 6, immediate=false);
    transition(stateB, stateC, v == 0, immediate=false);
    transition(stateC, stateA, true, immediate=false, priority=2);
    transition(stateC, stateD, count >= 2, immediate=false);

  public
    block StateX
      outer input Integer v;
      Integer i(start=0);
      Integer w;
    equation
      i = previous(i) + 1;
      w = v;
    end StateX;
    StateX stateX;

    block StateY
      Integer j(start=0);
    equation
      j = previous(j) + 1;
    end StateY;
    StateY stateY;

  equation
    transition(stateX, stateY, stateX.i > 20, immediate=false);
    initialState(stateX);
  end State1;

  block State2
    outer output Integer v;
  equation
    v = previous(v) + 5;
  end State2;

end HierarchicalAndParallelStateMachine;

// Result:
// class HierarchicalAndParallelStateMachine "Example from the MLS 3.3, Section 17.3.7"
//   discrete Integer state2.v(start = 0, fixed = true);
//   discrete Integer state1.stateC.count(start = 0, fixed = true);
//   discrete Integer state1.stateB.v(start = 0, fixed = true);
//   discrete Integer state1.stateA.v(start = 0, fixed = true);
//   Integer state1.stateY.j_previous;
//   Integer state1.stateX.i_previous;
//   discrete Boolean smOf.state1.stateX.stateMachineInFinalState;
//   discrete Boolean smOf.state1.stateX.finalStates[2];
//   discrete Boolean smOf.state1.stateX.nextResetStates[2](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateX.activeResetStates[2];
//   discrete Boolean smOf.state1.stateX.finalStates[1];
//   discrete Boolean smOf.state1.stateX.nextResetStates[1](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateX.activeResetStates[1];
//   discrete Boolean smOf.state1.stateX.nextReset(start = false, fixed = true);
//   discrete Integer smOf.state1.stateX.nextState(start = 0, fixed = true);
//   discrete Boolean smOf.state1.stateX.activeReset;
//   discrete Integer smOf.state1.stateX.activeState;
//   discrete Integer smOf.state1.stateX.fired;
//   discrete Boolean smOf.state1.stateX.selectedReset;
//   discrete Integer smOf.state1.stateX.selectedState;
//   discrete Boolean smOf.state1.stateX.reset;
//   discrete Boolean smOf.state1.stateX.active;
//   discrete Boolean smOf.state1.stateX.c[1];
//   discrete Boolean smOf.state1.stateX.cImmediate[1](start = false, fixed = true);
//   final parameter Integer smOf.state1.stateX.tPriority[1] = 1;
//   final parameter Boolean smOf.state1.stateX.tSynchronize[1] = false;
//   final parameter Boolean smOf.state1.stateX.tReset[1] = true;
//   final parameter Boolean smOf.state1.stateX.tImmediate[1] = false;
//   final parameter Integer smOf.state1.stateX.tTo[1] = 2;
//   final parameter Integer smOf.state1.stateX.tFrom[1] = 1;
//   final parameter Integer smOf.state1.stateX.nState = 2;
//   Real state1.stateY.$timeEnteredState(start = 0.0, fixed = true);
//   Real state1.stateY.$timeInState(start = 0.0, fixed = true);
//   discrete Integer state1.stateY.$ticksInState(start = 0, fixed = true);
//   discrete Boolean state1.stateY.active(start = false, fixed = true);
//   Real state1.stateX.$timeEnteredState(start = 0.0, fixed = true);
//   Real state1.stateX.$timeInState(start = 0.0, fixed = true);
//   discrete Integer state1.stateX.$ticksInState(start = 0, fixed = true);
//   discrete Boolean state1.stateX.active(start = false, fixed = true);
//   discrete Boolean smOf.state1.stateX.init(start = true, fixed = true);
//   discrete Boolean smOf.state1.stateA.stateMachineInFinalState;
//   discrete Boolean smOf.state1.stateA.finalStates[4];
//   discrete Boolean smOf.state1.stateA.nextResetStates[4](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateA.activeResetStates[4];
//   discrete Boolean smOf.state1.stateA.finalStates[3];
//   discrete Boolean smOf.state1.stateA.nextResetStates[3](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateA.activeResetStates[3];
//   discrete Boolean smOf.state1.stateA.finalStates[2];
//   discrete Boolean smOf.state1.stateA.nextResetStates[2](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateA.activeResetStates[2];
//   discrete Boolean smOf.state1.stateA.finalStates[1];
//   discrete Boolean smOf.state1.stateA.nextResetStates[1](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateA.activeResetStates[1];
//   discrete Boolean smOf.state1.stateA.nextReset(start = false, fixed = true);
//   discrete Integer smOf.state1.stateA.nextState(start = 0, fixed = true);
//   discrete Boolean smOf.state1.stateA.activeReset;
//   discrete Integer smOf.state1.stateA.activeState;
//   discrete Integer smOf.state1.stateA.fired;
//   discrete Boolean smOf.state1.stateA.selectedReset;
//   discrete Integer smOf.state1.stateA.selectedState;
//   discrete Boolean smOf.state1.stateA.reset;
//   discrete Boolean smOf.state1.stateA.active;
//   discrete Boolean smOf.state1.stateA.c[4];
//   discrete Boolean smOf.state1.stateA.cImmediate[4](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateA.c[3];
//   discrete Boolean smOf.state1.stateA.cImmediate[3](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateA.c[2];
//   discrete Boolean smOf.state1.stateA.cImmediate[2](start = false, fixed = true);
//   discrete Boolean smOf.state1.stateA.c[1];
//   discrete Boolean smOf.state1.stateA.cImmediate[1](start = false, fixed = true);
//   final parameter Integer smOf.state1.stateA.tPriority[4] = 2;
//   final parameter Boolean smOf.state1.stateA.tSynchronize[4] = false;
//   final parameter Boolean smOf.state1.stateA.tReset[4] = true;
//   final parameter Boolean smOf.state1.stateA.tImmediate[4] = false;
//   final parameter Integer smOf.state1.stateA.tTo[4] = 1;
//   final parameter Integer smOf.state1.stateA.tFrom[4] = 3;
//   final parameter Integer smOf.state1.stateA.tPriority[3] = 1;
//   final parameter Boolean smOf.state1.stateA.tSynchronize[3] = false;
//   final parameter Boolean smOf.state1.stateA.tReset[3] = true;
//   final parameter Boolean smOf.state1.stateA.tImmediate[3] = false;
//   final parameter Integer smOf.state1.stateA.tTo[3] = 2;
//   final parameter Integer smOf.state1.stateA.tFrom[3] = 1;
//   final parameter Integer smOf.state1.stateA.tPriority[2] = 1;
//   final parameter Boolean smOf.state1.stateA.tSynchronize[2] = false;
//   final parameter Boolean smOf.state1.stateA.tReset[2] = true;
//   final parameter Boolean smOf.state1.stateA.tImmediate[2] = false;
//   final parameter Integer smOf.state1.stateA.tTo[2] = 3;
//   final parameter Integer smOf.state1.stateA.tFrom[2] = 2;
//   final parameter Integer smOf.state1.stateA.tPriority[1] = 1;
//   final parameter Boolean smOf.state1.stateA.tSynchronize[1] = false;
//   final parameter Boolean smOf.state1.stateA.tReset[1] = true;
//   final parameter Boolean smOf.state1.stateA.tImmediate[1] = false;
//   final parameter Integer smOf.state1.stateA.tTo[1] = 4;
//   final parameter Integer smOf.state1.stateA.tFrom[1] = 3;
//   final parameter Integer smOf.state1.stateA.nState = 4;
//   Real state1.stateD.$timeEnteredState(start = 0.0, fixed = true);
//   Real state1.stateD.$timeInState(start = 0.0, fixed = true);
//   discrete Integer state1.stateD.$ticksInState(start = 0, fixed = true);
//   discrete Boolean state1.stateD.active(start = false, fixed = true);
//   Real state1.stateC.$timeEnteredState(start = 0.0, fixed = true);
//   Real state1.stateC.$timeInState(start = 0.0, fixed = true);
//   discrete Integer state1.stateC.$ticksInState(start = 0, fixed = true);
//   discrete Boolean state1.stateC.active(start = false, fixed = true);
//   Real state1.stateB.$timeEnteredState(start = 0.0, fixed = true);
//   Real state1.stateB.$timeInState(start = 0.0, fixed = true);
//   discrete Integer state1.stateB.$ticksInState(start = 0, fixed = true);
//   discrete Boolean state1.stateB.active(start = false, fixed = true);
//   Real state1.stateA.$timeEnteredState(start = 0.0, fixed = true);
//   Real state1.stateA.$timeInState(start = 0.0, fixed = true);
//   discrete Integer state1.stateA.$ticksInState(start = 0, fixed = true);
//   discrete Boolean state1.stateA.active(start = false, fixed = true);
//   discrete Boolean smOf.state1.stateA.init(start = true, fixed = true);
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
//   Integer v(start = 0);
//   Integer state1.count(start = 0);
//   Integer state1.v;
//   Integer state1.stateX.i(start = 0);
//   Integer state1.stateX.w;
//   Integer state1.stateY.j(start = 0);
// equation
//   v = if state1.active then state1.v else if state2.active then state2.v else previous(v);
//   state1.count = if state1.stateC.active then state1.stateC.count else previous(state1.count);
//   state1.v = if state1.stateA.active then state1.stateA.v else if state1.stateB.active then state1.stateB.v else previous(state1.v);
//   state2.v = if state2.active then previous(v) + 5 else previous(state2.v);
//   state1.stateC.count = if state1.stateC.active then previous(state1.count) + 1 else previous(state1.stateC.count);
//   state1.stateB.v = if state1.stateB.active then previous(state1.v) - 1 else previous(state1.stateB.v);
//   state1.stateA.v = if state1.stateA.active then previous(state1.v) + 2 else previous(state1.stateA.v);
//   state1.stateY.j_previous = if state1.stateY.active and (smOf.state1.stateX.activeReset or smOf.state1.stateX.activeResetStates[2]) then 0 else previous(state1.stateY.j);
//   state1.stateY.j = if state1.stateY.active then state1.stateY.j_previous + 1 else state1.stateY.j_previous;
//   state1.stateX.i_previous = if state1.stateX.active and (smOf.state1.stateX.activeReset or smOf.state1.stateX.activeResetStates[1]) then 0 else previous(state1.stateX.i);
//   state1.stateX.i = if state1.stateX.active then state1.stateX.i_previous + 1 else state1.stateX.i_previous;
//   state1.stateX.w = if state1.stateX.active then state1.v else previous(state1.stateX.w);
//   smOf.state1.stateX.stateMachineInFinalState = smOf.state1.stateX.finalStates[smOf.state1.stateX.activeState];
//   smOf.state1.stateX.finalStates[2] = (if smOf.state1.stateX.tFrom[1] == 2 then 1 else 0) == 0;
//   smOf.state1.stateX.finalStates[1] = (if smOf.state1.stateX.tFrom[1] == 1 then 1 else 0) == 0;
//   smOf.state1.stateX.nextResetStates[2] = if smOf.state1.stateX.active then if smOf.state1.stateX.activeState == 2 then false else smOf.state1.stateX.activeResetStates[2] else previous(smOf.state1.stateX.nextResetStates[2]);
//   smOf.state1.stateX.nextResetStates[1] = if smOf.state1.stateX.active then if smOf.state1.stateX.activeState == 1 then false else smOf.state1.stateX.activeResetStates[1] else previous(smOf.state1.stateX.nextResetStates[1]);
//   smOf.state1.stateX.activeResetStates[2] = if smOf.state1.stateX.reset then true else previous(smOf.state1.stateX.nextResetStates[2]);
//   smOf.state1.stateX.activeResetStates[1] = if smOf.state1.stateX.reset then true else previous(smOf.state1.stateX.nextResetStates[1]);
//   smOf.state1.stateX.nextReset = if smOf.state1.stateX.active then false else previous(smOf.state1.stateX.nextReset);
//   smOf.state1.stateX.nextState = if smOf.state1.stateX.active then smOf.state1.stateX.activeState else previous(smOf.state1.stateX.nextState);
//   smOf.state1.stateX.activeReset = if smOf.state1.stateX.reset then true else if smOf.state1.stateX.fired > 0 then smOf.state1.stateX.tReset[smOf.state1.stateX.fired] else smOf.state1.stateX.selectedReset;
//   smOf.state1.stateX.activeState = if smOf.state1.stateX.reset then 1 else if smOf.state1.stateX.fired > 0 then smOf.state1.stateX.tTo[smOf.state1.stateX.fired] else smOf.state1.stateX.selectedState;
//   smOf.state1.stateX.fired = if if smOf.state1.stateX.tFrom[1] == smOf.state1.stateX.selectedState then smOf.state1.stateX.c[1] else false then 1 else 0;
//   smOf.state1.stateX.selectedReset = if smOf.state1.stateX.reset then true else previous(smOf.state1.stateX.nextReset);
//   smOf.state1.stateX.selectedState = if smOf.state1.stateX.reset then 1 else previous(smOf.state1.stateX.nextState);
//   smOf.state1.stateX.c[1] = previous(smOf.state1.stateX.cImmediate[1]);
//   smOf.state1.stateX.cImmediate[1] = state1.stateX.i > 20;
//   state1.stateY.$timeEnteredState = if previous(state1.stateY.active) == false and state1.stateY.active == true then sample(time, Clock()) else previous(state1.stateY.$timeEnteredState);
//   state1.stateY.$timeInState = if state1.stateY.active then sample(time, Clock()) - state1.stateY.$timeEnteredState else 0.0;
//   state1.stateY.$ticksInState = if not state1.stateY.active then 0 else previous(state1.stateY.$ticksInState) + 1;
//   state1.stateY.active = smOf.state1.stateX.active and smOf.state1.stateX.activeState == 2;
//   state1.stateX.$timeEnteredState = if previous(state1.stateX.active) == false and state1.stateX.active == true then sample(time, Clock()) else previous(state1.stateX.$timeEnteredState);
//   state1.stateX.$timeInState = if state1.stateX.active then sample(time, Clock()) - state1.stateX.$timeEnteredState else 0.0;
//   state1.stateX.$ticksInState = if not state1.stateX.active then 0 else previous(state1.stateX.$ticksInState) + 1;
//   state1.stateX.active = smOf.state1.stateX.active and smOf.state1.stateX.activeState == 1;
//   smOf.state1.stateX.active = true;
//   smOf.state1.stateX.reset = previous(smOf.state1.stateX.init);
//   smOf.state1.stateX.init = false;
//   smOf.state1.stateA.stateMachineInFinalState = smOf.state1.stateA.finalStates[smOf.state1.stateA.activeState];
//   smOf.state1.stateA.finalStates[4] = max({if smOf.state1.stateA.tFrom[1] == 4 then 1 else 0, if smOf.state1.stateA.tFrom[2] == 4 then 1 else 0, if smOf.state1.stateA.tFrom[3] == 4 then 1 else 0, if smOf.state1.stateA.tFrom[4] == 4 then 1 else 0}) == 0;
//   smOf.state1.stateA.finalStates[3] = max({if smOf.state1.stateA.tFrom[1] == 3 then 1 else 0, if smOf.state1.stateA.tFrom[2] == 3 then 1 else 0, if smOf.state1.stateA.tFrom[3] == 3 then 1 else 0, if smOf.state1.stateA.tFrom[4] == 3 then 1 else 0}) == 0;
//   smOf.state1.stateA.finalStates[2] = max({if smOf.state1.stateA.tFrom[1] == 2 then 1 else 0, if smOf.state1.stateA.tFrom[2] == 2 then 1 else 0, if smOf.state1.stateA.tFrom[3] == 2 then 1 else 0, if smOf.state1.stateA.tFrom[4] == 2 then 1 else 0}) == 0;
//   smOf.state1.stateA.finalStates[1] = max({if smOf.state1.stateA.tFrom[1] == 1 then 1 else 0, if smOf.state1.stateA.tFrom[2] == 1 then 1 else 0, if smOf.state1.stateA.tFrom[3] == 1 then 1 else 0, if smOf.state1.stateA.tFrom[4] == 1 then 1 else 0}) == 0;
//   smOf.state1.stateA.nextResetStates[4] = if smOf.state1.stateA.active then if smOf.state1.stateA.activeState == 4 then false else smOf.state1.stateA.activeResetStates[4] else previous(smOf.state1.stateA.nextResetStates[4]);
//   smOf.state1.stateA.nextResetStates[3] = if smOf.state1.stateA.active then if smOf.state1.stateA.activeState == 3 then false else smOf.state1.stateA.activeResetStates[3] else previous(smOf.state1.stateA.nextResetStates[3]);
//   smOf.state1.stateA.nextResetStates[2] = if smOf.state1.stateA.active then if smOf.state1.stateA.activeState == 2 then false else smOf.state1.stateA.activeResetStates[2] else previous(smOf.state1.stateA.nextResetStates[2]);
//   smOf.state1.stateA.nextResetStates[1] = if smOf.state1.stateA.active then if smOf.state1.stateA.activeState == 1 then false else smOf.state1.stateA.activeResetStates[1] else previous(smOf.state1.stateA.nextResetStates[1]);
//   smOf.state1.stateA.activeResetStates[4] = if smOf.state1.stateA.reset then true else previous(smOf.state1.stateA.nextResetStates[4]);
//   smOf.state1.stateA.activeResetStates[3] = if smOf.state1.stateA.reset then true else previous(smOf.state1.stateA.nextResetStates[3]);
//   smOf.state1.stateA.activeResetStates[2] = if smOf.state1.stateA.reset then true else previous(smOf.state1.stateA.nextResetStates[2]);
//   smOf.state1.stateA.activeResetStates[1] = if smOf.state1.stateA.reset then true else previous(smOf.state1.stateA.nextResetStates[1]);
//   smOf.state1.stateA.nextReset = if smOf.state1.stateA.active then false else previous(smOf.state1.stateA.nextReset);
//   smOf.state1.stateA.nextState = if smOf.state1.stateA.active then smOf.state1.stateA.activeState else previous(smOf.state1.stateA.nextState);
//   smOf.state1.stateA.activeReset = if smOf.state1.stateA.reset then true else if smOf.state1.stateA.fired > 0 then smOf.state1.stateA.tReset[smOf.state1.stateA.fired] else smOf.state1.stateA.selectedReset;
//   smOf.state1.stateA.activeState = if smOf.state1.stateA.reset then 1 else if smOf.state1.stateA.fired > 0 then smOf.state1.stateA.tTo[smOf.state1.stateA.fired] else smOf.state1.stateA.selectedState;
//   smOf.state1.stateA.fired = max({if if smOf.state1.stateA.tFrom[1] == smOf.state1.stateA.selectedState then smOf.state1.stateA.c[1] else false then 1 else 0, if if smOf.state1.stateA.tFrom[2] == smOf.state1.stateA.selectedState then smOf.state1.stateA.c[2] else false then 2 else 0, if if smOf.state1.stateA.tFrom[3] == smOf.state1.stateA.selectedState then smOf.state1.stateA.c[3] else false then 3 else 0, if if smOf.state1.stateA.tFrom[4] == smOf.state1.stateA.selectedState then smOf.state1.stateA.c[4] else false then 4 else 0});
//   smOf.state1.stateA.selectedReset = if smOf.state1.stateA.reset then true else previous(smOf.state1.stateA.nextReset);
//   smOf.state1.stateA.selectedState = if smOf.state1.stateA.reset then 1 else previous(smOf.state1.stateA.nextState);
//   smOf.state1.stateA.c[4] = previous(smOf.state1.stateA.cImmediate[4]);
//   smOf.state1.stateA.cImmediate[4] = true;
//   smOf.state1.stateA.c[3] = previous(smOf.state1.stateA.cImmediate[3]);
//   smOf.state1.stateA.cImmediate[3] = state1.v >= 6;
//   smOf.state1.stateA.c[2] = previous(smOf.state1.stateA.cImmediate[2]);
//   smOf.state1.stateA.cImmediate[2] = state1.v == 0;
//   smOf.state1.stateA.c[1] = previous(smOf.state1.stateA.cImmediate[1]);
//   smOf.state1.stateA.cImmediate[1] = state1.count >= 2;
//   state1.stateD.$timeEnteredState = if previous(state1.stateD.active) == false and state1.stateD.active == true then sample(time, Clock()) else previous(state1.stateD.$timeEnteredState);
//   state1.stateD.$timeInState = if state1.stateD.active then sample(time, Clock()) - state1.stateD.$timeEnteredState else 0.0;
//   state1.stateD.$ticksInState = if not state1.stateD.active then 0 else previous(state1.stateD.$ticksInState) + 1;
//   state1.stateD.active = smOf.state1.stateA.active and smOf.state1.stateA.activeState == 4;
//   state1.stateC.$timeEnteredState = if previous(state1.stateC.active) == false and state1.stateC.active == true then sample(time, Clock()) else previous(state1.stateC.$timeEnteredState);
//   state1.stateC.$timeInState = if state1.stateC.active then sample(time, Clock()) - state1.stateC.$timeEnteredState else 0.0;
//   state1.stateC.$ticksInState = if not state1.stateC.active then 0 else previous(state1.stateC.$ticksInState) + 1;
//   state1.stateC.active = smOf.state1.stateA.active and smOf.state1.stateA.activeState == 3;
//   state1.stateB.$timeEnteredState = if previous(state1.stateB.active) == false and state1.stateB.active == true then sample(time, Clock()) else previous(state1.stateB.$timeEnteredState);
//   state1.stateB.$timeInState = if state1.stateB.active then sample(time, Clock()) - state1.stateB.$timeEnteredState else 0.0;
//   state1.stateB.$ticksInState = if not state1.stateB.active then 0 else previous(state1.stateB.$ticksInState) + 1;
//   state1.stateB.active = smOf.state1.stateA.active and smOf.state1.stateA.activeState == 2;
//   state1.stateA.$timeEnteredState = if previous(state1.stateA.active) == false and state1.stateA.active == true then sample(time, Clock()) else previous(state1.stateA.$timeEnteredState);
//   state1.stateA.$timeInState = if state1.stateA.active then sample(time, Clock()) - state1.stateA.$timeEnteredState else 0.0;
//   state1.stateA.$ticksInState = if not state1.stateA.active then 0 else previous(state1.stateA.$ticksInState) + 1;
//   state1.stateA.active = smOf.state1.stateA.active and smOf.state1.stateA.activeState == 1;
//   smOf.state1.stateA.active = true;
//   smOf.state1.stateA.reset = previous(smOf.state1.stateA.init);
//   smOf.state1.stateA.init = false;
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
//   smOf.state1.cImmediate[2] = state1.stateD.active and state1.stateY.active;
//   smOf.state1.c[1] = previous(smOf.state1.cImmediate[1]);
//   smOf.state1.cImmediate[1] = v >= 20;
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
// end HierarchicalAndParallelStateMachine;
// endResult
