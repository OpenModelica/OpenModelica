within ThermoSysPro.Examples.SimpleExamples;
model TestThreeWayValve
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP1 annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ThreeWayValve threeWayValve annotation(Placement(transformation(x=-10.0, y=34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP2 annotation(Placement(transformation(x=70.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Rampe rampe annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(SourceP1.C,threeWayValve.C1) annotation(Line(points={{-80,30},{-20,30}}, color={0,0,255}));
  connect(threeWayValve.C2,PuitsP1.C) annotation(Line(points={{0,30},{60,30}}, color={255,0,0}));
  connect(threeWayValve.C3,PuitsP2.C) annotation(Line(points={{-10,24},{-10,-10},{60,-10}}, color={255,0,0}));
  connect(rampe.y,threeWayValve.Ouv) annotation(Line(points={{-39,70},{-10,70},{-10,45}}));
end TestThreeWayValve;
