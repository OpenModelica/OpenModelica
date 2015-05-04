within ThermoSysPro.Examples.SimpleExamples;
model TestStodolaTurbine1
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.StodolaTurbine stodolaTurbine annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP(mode=0, P0=4500000.0) annotation(Placement(transformation(x=-10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP(h0=3000000.0, option_temperature=2, mode=2, P0=6500000.0) annotation(Placement(transformation(x=-90.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Machines.DynamicCentrifugalPump DynamicCentrifugalPump1(C2(P(start=300000.0)), Q(fixed=true, start=50)) annotation(Placement(transformation(x=30.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.ElectroMechanics.Machines.Shaft Shaft1 annotation(Placement(transformation(x=-10.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP1(mode=0, P0(fixed=false)=4500000.0) annotation(Placement(transformation(x=70.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP1(h0=3000000.0, option_temperature=2, mode=2, P0=1000000.0) annotation(Placement(transformation(x=-10.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(Shaft1.C2,DynamicCentrifugalPump1.M) annotation(Line(points={{1,-80},{30,-80},{30,-41}}));
  connect(stodolaTurbine.M,Shaft1.C1) annotation(Line(points={{-50,60},{-50,-80},{-21,-80}}));
  connect(sourceP1.C,DynamicCentrifugalPump1.C1) annotation(Line(points={{0,-30},{20,-30}}, color={0,0,255}));
  connect(DynamicCentrifugalPump1.C2,puitsP1.C) annotation(Line(points={{40,-30.2},{50,-30.2},{50,-30},{60,-30}}, color={0,0,255}));
  connect(sourceP.C,stodolaTurbine.Ce) annotation(Line(points={{-80,70},{-60.1,70}}, color={0,0,255}));
  connect(stodolaTurbine.Cs,puitsP.C) annotation(Line(points={{-39.9,70},{-20,70}}, color={0,0,255}));
end TestStodolaTurbine1;
