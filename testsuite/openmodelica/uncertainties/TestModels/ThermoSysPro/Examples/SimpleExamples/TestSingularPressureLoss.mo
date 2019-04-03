within ThermoSysPro.Examples.SimpleExamples;
model TestSingularPressureLoss
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP1 annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss(fluid=1) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(singularPressureLoss.C2,PuitsP1.C) annotation(Line(points={{0,30},{60,30}}, color={0,0,255}));
  connect(SourceP1.C,singularPressureLoss.C1) annotation(Line(points={{-80,30},{-20,30}}, color={0,0,255}));
end TestSingularPressureLoss;
