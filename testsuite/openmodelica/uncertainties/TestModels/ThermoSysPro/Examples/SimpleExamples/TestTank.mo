within ThermoSysPro.Examples.SimpleExamples;
model TestTank
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe PerteDP1 annotation(Placement(transformation(x=30.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ControlValve VanneReglante1 annotation(Placement(transformation(x=-50.0, y=22.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(transformation(x=-90.0, y=16.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP1 annotation(Placement(transformation(x=70.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.Tank Tank1(z(fixed=false, start=5)) annotation(Placement(transformation(x=-10.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Rampe Rampe1 annotation(Placement(transformation(x=-90.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(PerteDP1.C2,PuitsP1.C) annotation(Line(points={{40,-30},{60,-30}}, color={0,0,255}));
  connect(SourceP1.C,VanneReglante1.C1) annotation(Line(points={{-80,16},{-60,16}}, color={0,0,255}));
  connect(Tank1.Cs2,PerteDP1.C1) annotation(Line(points={{0,4},{10,4},{10,-30},{20,-30}}, color={0,0,255}));
  connect(Rampe1.y,VanneReglante1.Ouv) annotation(Line(points={{-79,50},{-50,50},{-50,33}}));
  connect(VanneReglante1.C2,Tank1.Ce1) annotation(Line(points={{-40,16},{-30,16},{-30,16},{-20,16}}, color={0,0,255}));
end TestTank;
