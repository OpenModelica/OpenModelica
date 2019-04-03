within ThermoSysPro.Examples.SimpleExamples;
model TestControlValve
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP1 annotation(Placement(transformation(x=70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.ControlValve ControlValve(mode_caract=1, caract=[0,0;0.5,3000;0.75,7000;1,8000]) annotation(Placement(transformation(x=-10.0, y=36.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Constante1(k=0.5) annotation(Placement(transformation(x=-30.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(ControlValve.C2,PuitsP1.C) annotation(Line(points={{0,30},{40,30},{40,30},{60,30}}, color={0,0,255}));
  connect(Constante1.y,ControlValve.Ouv) annotation(Line(points={{-19,70},{-10,70},{-10,47}}, color={0,0,255}));
  connect(SourceP1.C,ControlValve.C1) annotation(Line(points={{-80,30},{-20,30}}, color={0,0,255}));
end TestControlValve;
