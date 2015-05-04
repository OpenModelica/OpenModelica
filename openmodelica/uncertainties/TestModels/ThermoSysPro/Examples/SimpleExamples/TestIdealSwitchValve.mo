within ThermoSysPro.Examples.SimpleExamples;
model TestIdealSwitchValve
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP1 annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.IdealSwitchValve SwitchValve annotation(Placement(transformation(x=-10.0, y=36.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Logique.Pulse pulse(width=10, period=20) annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe perteDP2 annotation(Placement(transformation(x=-50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe perteDP1 annotation(Placement(transformation(x=30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(pulse.yL,SwitchValve.Ouv) annotation(Line(points={{-39,70},{-10,70},{-10,43}}, color={0,0,255}));
  connect(SourceP1.C,perteDP2.C1) annotation(Line(points={{-80,30},{-60,30}}, color={0,0,255}));
  connect(perteDP2.C2,SwitchValve.C1) annotation(Line(points={{-40,30},{-30,30},{-30,29.8},{-20,29.8}}, color={0,0,255}));
  connect(SwitchValve.C2,perteDP1.C1) annotation(Line(points={{0,30},{20,30}}, color={0,0,255}));
  connect(perteDP1.C2,PuitsP1.C) annotation(Line(points={{40,30},{60,30}}, color={0,0,255}));
end TestIdealSwitchValve;
