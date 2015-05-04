within ThermoSysPro.Examples.SimpleExamples;
model TestSteamDryer2
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Junctions.SteamDryer steamDryer(P(start=10000000.0), eta=0.9) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceQ(P0=10000000.0, h0=2400000) annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss2 annotation(Placement(transformation(x=-50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink sinkP annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss1 annotation(Placement(transformation(x=30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss3(K=0.002) annotation(Placement(transformation(x=10.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink sink annotation(Placement(transformation(x=50.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceQ.C,singularPressureLoss2.C1) annotation(Line(points={{-80,30},{-60,30}}, color={0,0,255}));
  connect(singularPressureLoss1.C2,sinkP.C) annotation(Line(points={{40,30},{60,30}}, color={0,0,255}));
  connect(singularPressureLoss3.C2,sink.C) annotation(Line(points={{20,-10},{40,-10}}, color={0,0,255}));
  connect(singularPressureLoss2.C2,steamDryer.Cev) annotation(Line(points={{-40,30},{-30,30},{-30,34},{-19.9,34}}, color={0,0,255}));
  connect(steamDryer.Csv,singularPressureLoss1.C1) annotation(Line(points={{-0.1,34},{10,34},{10,30},{20,30}}, color={0,0,255}));
  connect(steamDryer.Csl,singularPressureLoss3.C1) annotation(Line(points={{-9.9,20},{-10,20},{-10,-10},{0,-10}}, color={0,0,255}));
end TestSteamDryer2;
