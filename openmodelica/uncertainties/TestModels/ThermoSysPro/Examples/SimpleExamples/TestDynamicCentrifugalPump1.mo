within ThermoSysPro.Examples.SimpleExamples;
model TestDynamicCentrifugalPump1
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.DynamicCentrifugalPump DynamicCentrifugalPump1(C2(P(start=300000.0))) annotation(Placement(transformation(x=-10.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.Tank Tank(ze2=10, zs2=10, steady_state=false) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ControlValve Valve annotation(Placement(transformation(x=50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Constante1(k=0.5) annotation(Placement(transformation(x=10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.ElectroMechanics.BoundaryConditions.SourceMechanicalPower sourceTorque annotation(Placement(transformation(x=-60.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Pulse pulse(width=200, period=500, amplitude=150000) annotation(Placement(transformation(x=-90.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.ElectroMechanics.Machines.Shaft Shaft1 annotation(Placement(transformation(x=-30.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(DynamicCentrifugalPump1.C2,Tank.Ce2) annotation(Line(points={{-20,-30.2},{-60,-30.2},{-60,24},{-20,24}}, color={0,0,255}));
  connect(Tank.Cs2,Valve.C1) annotation(Line(points={{0,24},{40,24}}, color={0,0,255}));
  connect(Valve.C2,DynamicCentrifugalPump1.C1) annotation(Line(points={{60,24},{80,24},{80,-30},{0,-30}}, color={0,0,255}));
  connect(Constante1.y,Valve.Ouv) annotation(Line(points={{21,70},{50,70},{50,41}}, color={0,0,255}));
  connect(pulse.y,sourceTorque.IPower) annotation(Line(points={{-79,-70},{-65,-70}}));
  connect(Shaft1.C2,DynamicCentrifugalPump1.M) annotation(Line(points={{-19,-70},{-10,-70},{-10,-41}}));
  connect(sourceTorque.M,Shaft1.C1) annotation(Line(points={{-49,-70},{-41,-70}}));
end TestDynamicCentrifugalPump1;
