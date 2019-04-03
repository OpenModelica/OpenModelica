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
// stateMachine state1
//   state state1
//       Integer state1.count(start = 0);
//       output Integer state1.v;
//     stateMachine state1.stateX
//       state state1.stateX
//           Integer state1.stateX.i(start = 0);
//           Integer state1.stateX.w;
//         equation
//           state1.stateX.i = 1 + previous(state1.stateX.i);
//           state1.stateX.w = state1.v;
//       end state1.stateX;
//
//       state state1.stateY
//           Integer state1.stateY.j(start = 0);
//         equation
//           state1.stateY.j = 1 + previous(state1.stateY.j);
//       end state1.stateY;
//       equation
//         transition(state1.stateX, state1.stateY, state1.stateX.i > 20, false, true, false, 1);
//         initialState(state1.stateX);
//     end state1.stateX;
//
//     stateMachine state1.stateA
//       state state1.stateA
//           output Integer state1.stateA.v;
//         equation
//           state1.stateA.v = 2 + previous(v);
//       end state1.stateA;
//
//       state state1.stateB
//           output Integer state1.stateB.v;
//         equation
//           state1.stateB.v = -1 + previous(v);
//       end state1.stateB;
//
//       state state1.stateC
//           output Integer state1.stateC.count;
//         equation
//           state1.stateC.count = 1 + previous(state1.count);
//       end state1.stateC;
//
//       state state1.stateD
//       end state1.stateD;
//       equation
//         initialState(state1.stateA);
//         transition(state1.stateA, state1.stateB, state1.v >= 6, false, true, false, 1);
//         transition(state1.stateB, state1.stateC, state1.v == 0, false, true, false, 1);
//         transition(state1.stateC, state1.stateA, true, false, true, false, 2);
//         transition(state1.stateC, state1.stateD, state1.count >= 2, false, true, false, 1);
//     end state1.stateA;
//     equation
//       state1.v = if activeState(state1.stateA) then state1.stateA.v else if activeState(state1.stateB) then state1.stateB.v else previous(v);
//       state1.count = if activeState(state1.stateC) then state1.stateC.count else previous(state1.count);
//   end state1;
//
//   state state2
//       output Integer state2.v;
//     equation
//       state2.v = 5 + previous(v);
//   end state2;
//   equation
//     initialState(state1);
//     transition(state1, state2, activeState(state1.stateD) and activeState(state1.stateY), false, true, false, 1);
//     transition(state2, state1, v >= 20, false, true, false, 1);
// end state1;
// equation
//   v = if activeState(state1) then state1.v else if activeState(state2) then state2.v else previous(v);
// end HierarchicalAndParallelStateMachine;
// endResult
