within ThermoSysPro.Examples.SimpleExamples;
model TestStodolaTurbine
  annotation(Diagram);
  ThermoSysPro.WaterSteam.Machines.StodolaTurbine stodolaTurbine(fluid=1) annotation(Placement(transformation(x=-50.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP(mode=0, P0=4500000.0) annotation(Placement(transformation(x=-10.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP(h0=3000000.0, option_temperature=2, mode=2, P0=4800000.0) annotation(Placement(transformation(x=-90.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Machines.DynamicCentrifugalPump DynamicCentrifugalPump1 annotation(Placement(transformation(x=10.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.Volumes.Tank Bache1(ze2=10, zs2=10) annotation(Placement(transformation(x=10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ControlValve VanneReglante1 annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Constante1(k=0.5) annotation(Placement(transformation(x=30.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(DynamicCentrifugalPump1.C2,Bache1.Ce2) annotation(Line(points={{0,-30.2},{-10,-30},{-20,-30},{-20,24},{0,24}}, color={0,0,255}));
  connect(Bache1.Cs2,VanneReglante1.C1) annotation(Line(points={{20,24},{60,24}}, color={0,0,255}));
  connect(VanneReglante1.C2,DynamicCentrifugalPump1.C1) annotation(Line(points={{80,24},{100,24},{100,-30},{20,-30}}, color={0,0,255}));
  connect(Constante1.y,VanneReglante1.Ouv) annotation(Line(points={{41,70},{70,70},{70,41}}, color={0,0,255}));
  connect(sourceP.C,stodolaTurbine.Ce) annotation(Line(points={{-80,70},{-60.1,70}}, color={0,0,255}));
  connect(stodolaTurbine.Cs,puitsP.C) annotation(Line(points={{-39.9,70},{-20,70}}, color={0,0,255}));
  connect(stodolaTurbine.M,DynamicCentrifugalPump1.M) annotation(Line(points={{-50,60},{-50,-60},{10,-60},{10,-41}}, color={0,0,255}, smooth=0));
end TestStodolaTurbine;
