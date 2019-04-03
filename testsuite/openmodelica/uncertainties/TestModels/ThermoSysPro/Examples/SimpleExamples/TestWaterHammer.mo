within ThermoSysPro.Examples.SimpleExamples;
model TestWaterHammer
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP PSource1(P0=3000000) annotation(Placement(transformation(x=-90.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.WaterHammer waterHammer(L=600, D=0.5, lambda=0.018, a=1200) annotation(Placement(transformation(x=-50.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PSink1(P0=2400000) annotation(Placement(transformation(x=70.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  WaterSteam.PressureLosses.ControlValve VanneTORC1(continuous_flow_reversal=true) annotation(Placement(transformation(x=30.0, y=-4.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Blocks.Sources.Rampe rampe(Initialvalue=1, Finalvalue=0.01, Duration=0.15) annotation(Placement(transformation(x=-30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  WaterSteam.Volumes.VolumeA volumeA annotation(Placement(transformation(x=-10.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(PSource1.C,waterHammer.C1) annotation(Line(points={{-80,-10},{-60,-10}}, color={0,0,255}));
  connect(VanneTORC1.C2,PSink1.C) annotation(Line(points={{40,-10},{60,-10}}, color={0,0,255}));
  connect(rampe.y,VanneTORC1.Ouv) annotation(Line(points={{-19,30},{30,30},{30,7}}, color={0,0,255}, smooth=0));
  connect(waterHammer.C2,volumeA.Ce1) annotation(Line(points={{-40,-10},{-20,-10}}, color={0,0,255}, smooth=0));
  connect(volumeA.Cs1,VanneTORC1.C1) annotation(Line(points={{0,-10},{20,-10}}, color={0,0,255}, smooth=0));
end TestWaterHammer;
