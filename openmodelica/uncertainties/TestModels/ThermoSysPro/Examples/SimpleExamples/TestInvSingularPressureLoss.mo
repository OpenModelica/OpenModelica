within ThermoSysPro.Examples.SimpleExamples;
model TestInvSingularPressureLoss
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourcePQ annotation(Placement(transformation(x=-70.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkQ annotation(Placement(transformation(x=50.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.InvSingularPressureLoss invSingularPressureLoss annotation(Placement(transformation(x=-10.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourcePQ.C,invSingularPressureLoss.C1) annotation(Line(points={{-60,10},{-20,10}}, color={0,0,255}));
  connect(invSingularPressureLoss.C2,sinkQ.C) annotation(Line(points={{0,10},{40,10}}, color={0,0,255}));
end TestInvSingularPressureLoss;
