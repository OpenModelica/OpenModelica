within ;
block MLS33_17_3_7NA "Example from the MLS 3.3, Section 17.3.7, No Annotations"
  inner Integer v(start=0);
  model State1
    inner Integer count(start=0);
    inner outer output Integer v;
    StateA stateA;
    StateB stateB;
    StateC stateC;
    StateD stateD;
    StateX stateX;
    StateY stateY;
    model StateA
      outer output Integer v;
    equation
      v = previous(v) + 2;
    end StateA;

    model StateB
      outer output Integer v;
    equation
      v = previous(v) - 1;
    end StateB;

    model StateC
      outer output Integer count;
    equation
      count = previous(count) + 1;
    end StateC;

    model StateD
    end StateD;
  equation
    initialState(stateA);
    transition(stateA, stateB, v >= 6, immediate=false);
    transition(stateB, stateC, v == 0, immediate=false);
    transition(stateC, stateA, true, immediate=false, priority=2);
    transition(stateC, stateD, count >= 2, immediate=false);
  public
    model StateX
      outer input Integer v;
      Integer i(start=0);
      Integer w;
    equation
      i = previous(i) + 1;
      w = v;
    end StateX;

    model StateY
      Integer j(start=0);
    equation
      j = previous(j) + 1;
    end StateY;
  equation
    transition(stateX, stateY, stateX.i > 20, immediate=false);
    initialState(stateX);
  end State1;
  State1 state1;
  model State2
    outer output Integer v;
  equation
    v = previous(v) + 5;
  end State2;
  State2 state2;
equation
  transition(state1, state2, activeState(state1.stateD) and activeState(state1.stateY), immediate=false);
  transition(state2, state1, v >= 20, immediate=false);
  initialState(state1);
end MLS33_17_3_7NA;
