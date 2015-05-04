package ArrayReturn
  constant Integer N = 3;
  type AI = Real[N];
  type AIAI = AI[N];

  function RAI
    input Real x;
    output AI a;
  algorithm
    a := {1, 2, 3} * x;
  end RAI;

  function NextAIAI
    input AIAI state;
    input Real t;
    output AIAI next;
  algorithm
    for i loop
      next[i] := state[i] + RAI(t)*i;
    end for;
  end NextAIAI;

  model RAITest
    AI state(each start = 0, each fixed = true);
  algorithm
    when sample(0, 0.1) then
      state := pre(state) + RAI(time);
    end when;
  end RAITest;

  model RAIArrayTest
    AI state[N](each start = 0, each fixed = true);
  algorithm
    when sample(0, 0.1) then
      for i loop
  state[i] := state[i] + RAI(time);
      end for;
    end when;
  end RAIArrayTest;

  model AIAITest
    AIAI state(each start = 0, each fixed = true);
  algorithm
    when sample(0, 0.1) then
      state := NextAIAI(state, time);
    end when;
  end AIAITest;
end ArrayReturn;
