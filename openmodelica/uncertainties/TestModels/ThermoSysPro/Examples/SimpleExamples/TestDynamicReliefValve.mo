within ThermoSysPro.Examples.SimpleExamples;
model TestDynamicReliefValve
  ThermoSysPro.WaterSteam.PressureLosses.DynamicReliefValve ReliefValve(dPOuvert=200000.0, dPFerme=190000.0, Cmin=0, Cvmax=1000, D=1, m=1) annotation(Placement(transformation(x=10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe Pipe2 annotation(Placement(transformation(x=50.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP Sink2 annotation(Placement(transformation(x=90.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.Tank Tank(z0=70) annotation(Placement(transformation(x=-90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe Pipe1 annotation(Placement(transformation(x=-30.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.VolumeD VolumeD1 annotation(Placement(transformation(x=10.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP Sink1 annotation(Placement(transformation(x=50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(Pipe2.C2,Sink2.C) annotation(Line(points={{60,-10},{80,-10}}, color={0,0,255}));
  connect(Tank.Cs2,Pipe1.C1) annotation(Line(points={{-80,4},{-60,4},{-60,-10},{-40,-10}}, color={0,0,255}));
  connect(Pipe1.C2,VolumeD1.Ce) annotation(Line(points={{-20,-10},{0,-10}}, color={0,0,255}));
  connect(VolumeD1.Cs3,Pipe2.C1) annotation(Line(points={{20,-10},{40,-10}}, color={0,0,255}));
  connect(ReliefValve.C1,VolumeD1.Cs1) annotation(Line(points={{10,20.2},{10,0}}));
  connect(ReliefValve.C2,Sink1.C) annotation(Line(points={{20,29.8},{30,29.8},{30,30},{40,30}}, color={0,0,255}));
end TestDynamicReliefValve;
