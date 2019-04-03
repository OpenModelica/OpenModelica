model InOutTest

  Modelica.Blocks.Continuous.FirstOrder firstOrder
    annotation (Placement(transformation(extent={{-32,60},{-12,80}})));
  Modelica.Blocks.Interfaces.RealInput u
    annotation (Placement(transformation(extent={{-100,50},{-60,90}})));
  Modelica.Blocks.Continuous.PI PI
    annotation (Placement(transformation(extent={{8,60},{28,80}})));
  Modelica.Blocks.Interfaces.RealOutput y
    annotation (Placement(transformation(extent={{80,60},{100,80}})));
  Modelica.Blocks.Nonlinear.Limiter limiter(uMax=1)
    annotation (Placement(transformation(extent={{42,60},{62,80}})));
equation
  connect(u, firstOrder.u) annotation (Line(
      points={{-80,70},{-34,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(firstOrder.y, PI.u) annotation (Line(
      points={{-11,70},{6,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(PI.y, limiter.u) annotation (Line(
      points={{29,70},{40,70}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(limiter.y, y) annotation (Line(
      points={{63,70},{90,70}},
      color={0,0,127},
      smooth=Smooth.None));
end InOutTest;
