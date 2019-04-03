within ThermoSysPro.Examples.SimpleExamples;
model TestDiaphragm
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP SourceP1 annotation(Placement(transformation(x=-70.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP PuitsP1 annotation(Placement(transformation(x=50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.Diaphragm Diaphragm annotation(Placement(transformation(x=-10.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(Diaphragm.C2,PuitsP1.C) annotation(Line(points={{0,30},{40,30}}, color={0,0,255}));
  connect(SourceP1.C,Diaphragm.C1) annotation(Line(points={{-60,30},{-20,30}}, color={0,0,255}));
end TestDiaphragm;
