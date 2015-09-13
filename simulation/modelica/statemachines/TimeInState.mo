within ;
model TimeInState "Test for TimeInState"
  inner Integer i(start = 0);

  block State1
    outer output Integer i;
  equation
    i = previous(i) + 2;
    annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
  end State1;

  State1 state1 annotation(Placement(transformation(extent={{-56,62},{-10,76}})));

  block State2
    outer output Integer i;
  equation
    i = previous(i) - 1;
    annotation(Icon(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(graphics={  Text(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, textString = "%stateText", fontSize = 10)}), __Dymola_state = true, showDiagram = true, singleInstance = true);
  end State2;

  State2 state2 annotation(Placement(transformation(extent={{-56,40},{-12,54}})));
equation
  transition(state1, state2, timeInState() > 4,
                                     immediate=false,   reset=true,   synchronize=false,   priority=1)   annotation(Line(points={{-8,69},
          {-4,58},{-10,47}},                                                                                                   color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(string = "%condition", extent = {{6, -4}, {6, -10}}, lineColor = {95, 95, 95}, fontSize=10,   textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Left));
  transition(state2, state1, timeInState() > 5,
                                    immediate=false,   reset=true,   synchronize=false,   priority=1)   annotation(Line(points={{-58,47},
          {-66,58},{-58,69}},                                                                                                    color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier), Text(string = "%condition", extent = {{-6, 4}, {-6, 10}}, lineColor = {95, 95, 95}, fontSize=10,   textStyle = {TextStyle.Bold}, horizontalAlignment = TextAlignment.Right));
  initialState(state1) annotation(Line(points={{-34.5336,78},{-36,84}},      color = {175, 175, 175}, thickness = 0.25, smooth = Smooth.Bezier, arrow = {Arrow.Filled, Arrow.None}));
  annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics={  Text(extent = {{-62, 94}, {-12, 84}}, lineColor = {0, 0, 0}, fontSize = 10,
            horizontalAlignment = TextAlignment.Left, textString = "%declarations")}));
end TimeInState;
