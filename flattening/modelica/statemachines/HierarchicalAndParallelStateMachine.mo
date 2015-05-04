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
//   Integer v(start = 0);
//   Integer state1.count(start = 0);
//   output Integer state1.v = v;
//   output Integer state1.stateA.v = state1.v;
//   output Integer state1.stateB.v = state1.v;
//   output Integer state1.stateC.count = state1.count;
//   Integer state1.stateX.i(start = 0);
//   Integer state1.stateX.w;
//   Integer state1.stateY.j(start = 0);
//   output Integer state2.v = v;
// equation
//   state1.stateA.v = 2 + previous(state1.stateA.v);
//   state1.stateB.v = -1 + previous(state1.stateB.v);
//   state1.stateC.count = 1 + previous(state1.stateC.count);
//   state1.stateX.i = 1 + previous(state1.stateX.i);
//   state1.stateX.w = state1.v;
//   state1.stateY.j = 1 + previous(state1.stateY.j);
//   transition(state1.stateX, state1.stateY, state1.stateX.i > 20, false, true, false, 1);
//   initialState(state1.stateX);
//   initialState(state1.stateA);
//   transition(state1.stateA, state1.stateB, state1.v >= 6, false, true, false, 1);
//   transition(state1.stateB, state1.stateC, state1.v == 0, false, true, false, 1);
//   transition(state1.stateC, state1.stateA, true, false, true, false, 2);
//   transition(state1.stateC, state1.stateD, state1.count >= 2, false, true, false, 1);
//   state2.v = 5 + previous(state2.v);
//   initialState(state1);
//   transition(state1, state2, activeState(state1.stateD) and activeState(state1.stateY), false, true, false, 1);
//   transition(state2, state1, v >= 20, false, true, false, 1);
// end HierarchicalAndParallelStateMachine;
// endResult