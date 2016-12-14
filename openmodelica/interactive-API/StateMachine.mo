within;
model StateMachine
  model State1
  end State1;
  State1 state1;
  model State2
  end State2;
  State2 state2;
equation
  connect(a, b) annotation (Line(
      points={{-28,36},{0,72}},
      color={175,175,175},
      thickness=0.25,
      smooth=Smooth.Bezier,
      arrow={Arrow.Filled,Arrow.None}));
  transition(state1, state2, i > 10, true, immediate=false) annotation (Line(
      points={{-8,6},{0,72}},
      color={175,175,175},
      thickness=0.25,
      arrow={Arrow.Filled,Arrow.None}));
  initialState(state1);
  transition(state2, state1, b > 10, reset=false);
  transition(state2, state1, c > 20, false, false, true) annotation (Line(
      points={{-8,6},{0,72}},
      color={175,175,175},
      thickness=0.25,
      arrow={Arrow.Filled,Arrow.None}));
end StateMachine;