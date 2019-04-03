within ThermoSysPro.Examples.SimpleExamples;
model TestStodolaTurbine2
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.StodolaTurbine stodolaTurbine annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP(mode=0, P0=5000) annotation(Placement(transformation(x=-10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP(h0=3000000.0, option_temperature=2, mode=2, P0=300000.0) annotation(Placement(transformation(x=-90.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP.C,stodolaTurbine.Ce) annotation(Line(points={{-80,70},{-60.1,70}}, color={0,0,255}));
  connect(stodolaTurbine.Cs,puitsP.C) annotation(Line(points={{-39.9,70},{-20,70}}, color={0,0,255}));
end TestStodolaTurbine2;
