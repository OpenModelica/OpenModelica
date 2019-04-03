within ThermoSysPro.Examples.SimpleExamples;
model TestSwitchValve
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP1 annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SwitchValve SwitchValve annotation(Placement(transformation(x=-10.0, y=36.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Logique.Pulse pulse(width=10, period=20) annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(SwitchValve.C2,PuitsP1.C) annotation(Line(points={{0,30.2},{40,30.2},{40,30},{60,30}}, color={0,0,255}));
  connect(SourceP1.C,SwitchValve.C1) annotation(Line(points={{-80,30},{-20,30}}, color={0,0,255}));
  connect(pulse.yL,SwitchValve.Ouv) annotation(Line(points={{-39,70},{-10,70},{-10,43.2}}, color={0,0,255}));
end TestSwitchValve;
