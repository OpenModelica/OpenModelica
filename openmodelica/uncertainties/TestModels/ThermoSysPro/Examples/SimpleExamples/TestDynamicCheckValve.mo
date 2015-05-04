within ThermoSysPro.Examples.SimpleExamples;
model TestDynamicCheckValve
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP1 annotation(Placement(transformation(x=-30.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP1(P0=600000.0) annotation(Placement(transformation(x=50.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Pulse pulse(amplitude=600000.0, width=50, period=100, offset=300000.0) annotation(Placement(transformation(x=-70.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.DynamicCheckValve checkValve3(J=10) annotation(Placement(transformation(x=10.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP1.C,checkValve3.C1) annotation(Line(points={{-20,50},{0,50}}, color={0,0,255}));
  connect(checkValve3.C2,puitsP1.C) annotation(Line(points={{20,49.8},{30,49.8},{30,50},{40,50}}, color={0,0,255}));
  connect(pulse.y,sourceP1.IPressure) annotation(Line(points={{-59,50},{-35,50}}, color={0,0,255}));
end TestDynamicCheckValve;
