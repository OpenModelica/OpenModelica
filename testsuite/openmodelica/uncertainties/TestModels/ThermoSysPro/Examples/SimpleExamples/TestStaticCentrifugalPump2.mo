within ThermoSysPro.Examples.SimpleExamples;
model TestStaticCentrifugalPump2
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.StaticCentrifugalPump StaticCentrifugalPump1(fixed_rot_or_power=2) annotation(Placement(transformation(x=-10.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.Tank Bache1(ze2=10, zs2=10) annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ControlValve VanneReglante1 annotation(Placement(transformation(x=50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Constante1(k=0.5) annotation(Placement(transformation(x=10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Pulse pulse(width=200, period=500, amplitude=50000.0, startTime=0, offset=1000) annotation(Placement(transformation(x=-70.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(StaticCentrifugalPump1.C2,Bache1.Ce2) annotation(Line(points={{-20,-30},{-60,-30},{-60,24},{-20,24}}, color={0,0,255}));
  connect(Bache1.Cs2,VanneReglante1.C1) annotation(Line(points={{0,24},{40,24}}, color={0,0,255}));
  connect(VanneReglante1.C2,StaticCentrifugalPump1.C1) annotation(Line(points={{60,24},{80,24},{80,-30},{0,-30}}, color={0,0,255}));
  connect(Constante1.y,VanneReglante1.Ouv) annotation(Line(points={{21,70},{50,70},{50,41}}, color={0,0,255}));
  connect(pulse.y,StaticCentrifugalPump1.rpm_or_mpower) annotation(Line(points={{-59,-60},{-10,-60},{-10,-41}}, color={0,0,255}, smooth=0));
end TestStaticCentrifugalPump2;
