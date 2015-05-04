within ThermoSysPro.Examples.SimpleExamples;
model TestCompressor
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.Compressor compressor(Pe(start=100000)) annotation(Placement(transformation(x=-10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink puitsP annotation(Placement(transformation(x=70.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP(P0=100000, Q0=1, h0=30000.0) annotation(Placement(transformation(x=-90.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe lumpedStraightPipe(fluid=2) annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe lumpedStraightPipe1(fluid=2) annotation(Placement(transformation(x=30.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP.C,lumpedStraightPipe.C1) annotation(Line(points={{-80,70},{-60,70}}, color={0,0,255}));
  connect(lumpedStraightPipe.C2,compressor.C1) annotation(Line(points={{-40,70},{-20,70}}, color={0,0,255}));
  connect(compressor.C2,lumpedStraightPipe1.C1) annotation(Line(points={{0,70},{20,70}}, color={0,0,255}));
  connect(lumpedStraightPipe1.C2,puitsP.C) annotation(Line(points={{40,70},{60,70}}, color={0,0,255}));
end TestCompressor;
