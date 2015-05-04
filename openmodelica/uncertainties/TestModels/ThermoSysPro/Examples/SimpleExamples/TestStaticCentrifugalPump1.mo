within ThermoSysPro.Examples.SimpleExamples;
model TestStaticCentrifugalPump1
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.StaticCentrifugalPump StaticCentrifugalPump1(fixed_rot_or_power=2, MPower=150000.0) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  WaterSteam.BoundaryConditions.SourceP sourceP annotation(Placement(transformation(x=-70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  WaterSteam.BoundaryConditions.SinkP sinkP(P0=600000) annotation(Placement(transformation(x=50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP.C,StaticCentrifugalPump1.C1) annotation(Line(points={{-60,30},{-20,30}}, color={0,0,255}, smooth=0));
  connect(StaticCentrifugalPump1.C2,sinkP.C) annotation(Line(points={{0,30},{40,30}}, color={0,0,255}, smooth=0));
end TestStaticCentrifugalPump1;
