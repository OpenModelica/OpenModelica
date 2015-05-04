within ThermoSysPro.Examples.SimpleExamples;
model TestDynamicCentrifugalPump
  annotation(Diagram);
  ThermoSysPro.InstrumentationAndControl.Blocks.Logique.Pulse Pulse1(width=200, period=400) annotation(Placement(transformation(x=-90.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.ElectroMechanics.Machines.SynchronousMotor Motor1 annotation(Placement(transformation(x=-70.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Machines.DynamicCentrifugalPump DynamicCentrifugalPump1 annotation(Placement(transformation(x=-10.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.Tank Tank(ze2=10, zs2=10) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ControlValve Valve annotation(Placement(transformation(x=50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Constante1(k=0.5) annotation(Placement(transformation(x=10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.ElectroMechanics.Machines.Shaft Shaft1 annotation(Placement(transformation(x=-30.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(Pulse1.yL,Motor1.marche) annotation(Line(points={{-79,-50},{-70,-50},{-70,-65.6}}));
  connect(DynamicCentrifugalPump1.C2,Tank.Ce2) annotation(Line(points={{-20,-30.2},{-60,-30.2},{-60,24},{-20,24}}, color={0,0,255}));
  connect(Tank.Cs2,Valve.C1) annotation(Line(points={{0,24},{40,24}}, color={0,0,255}));
  connect(Valve.C2,DynamicCentrifugalPump1.C1) annotation(Line(points={{60,24},{80,24},{80,-30},{0,-30}}, color={0,0,255}));
  connect(Constante1.y,Valve.Ouv) annotation(Line(points={{21,70},{50,70},{50,41}}, color={0,0,255}));
  connect(Motor1.C,Shaft1.C1) annotation(Line(points={{-59.8,-70},{-41,-70}}));
  connect(DynamicCentrifugalPump1.M,Shaft1.C2) annotation(Line(points={{-10,-41},{-10,-70},{-19,-70}}));
end TestDynamicCentrifugalPump;
