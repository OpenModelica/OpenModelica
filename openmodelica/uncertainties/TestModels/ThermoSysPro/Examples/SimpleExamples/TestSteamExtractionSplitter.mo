within ThermoSysPro.Examples.SimpleExamples;
model TestSteamExtractionSplitter
  ThermoSysPro.WaterSteam.Junctions.SteamExtractionSplitter steamExtractionSplitter(alpha=0.9) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceQ sourceQ(h0=2600000) annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss2 annotation(Placement(transformation(x=-50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP(P0=10000000.0) annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss1 annotation(Placement(transformation(x=30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss3(K=0.002) annotation(Placement(transformation(x=10.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkQ sink(Q0=10) annotation(Placement(transformation(x=50.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceQ.C,singularPressureLoss2.C1) annotation(Line(points={{-80,30},{-60,30}}, color={0,0,255}));
  connect(singularPressureLoss2.C2,steamExtractionSplitter.Ce) annotation(Line(points={{-40,30},{-20.3,30}}, color={0,0,255}));
  connect(steamExtractionSplitter.Cs,singularPressureLoss1.C1) annotation(Line(points={{0.3,30},{20,30}}, color={0,0,255}));
  connect(steamExtractionSplitter.Cex,singularPressureLoss3.C1) annotation(Line(points={{-6,20},{-6,-10},{0,-10}}, color={0,0,255}));
  connect(singularPressureLoss1.C2,sinkP.C) annotation(Line(points={{40,30},{60,30}}, color={0,0,255}));
  connect(singularPressureLoss3.C2,sink.C) annotation(Line(points={{20,-10},{40,-10}}, color={0,0,255}));
end TestSteamExtractionSplitter;
