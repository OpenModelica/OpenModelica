within ThermoSysPro.Examples.SimpleExamples;
model TestLumpedStraightPipe
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP1 annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe lumpedStraightPipe annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.Tank tank annotation(Placement(transformation(x=-50.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.Tank tank1(z0=10) annotation(Placement(transformation(x=30.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe lumpedStraightPipe1(inertia=true, lambda_fixed=false) annotation(Placement(transformation(x=-10.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(lumpedStraightPipe.C2,PuitsP1.C) annotation(Line(points={{0,30},{60,30}}, color={0,0,255}));
  connect(SourceP1.C,lumpedStraightPipe.C1) annotation(Line(points={{-80,30},{-20,30}}, color={0,0,255}));
  connect(tank.Cs2,lumpedStraightPipe1.C1) annotation(Line(points={{-40,-36},{-30,-36},{-30,-70},{-20,-70}}, color={0,0,255}));
  connect(lumpedStraightPipe1.C2,tank1.Ce2) annotation(Line(points={{0,-70},{10,-70},{10,-36},{20,-36}}, color={0,0,255}));
end TestLumpedStraightPipe;
