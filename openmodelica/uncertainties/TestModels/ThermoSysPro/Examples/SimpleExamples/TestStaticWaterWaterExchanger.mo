within ThermoSysPro.Examples.SimpleExamples;
model TestStaticWaterWaterExchanger
  annotation(Diagram);
  ThermoSysPro.WaterSteam.HeatExchangers.StaticWaterWaterExchanger plateHeatExchanger(modec=1, modef=1) annotation(Placement(transformation(x=-10.0, y=54.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=340) annotation(Placement(transformation(x=-70.0, y=54.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP3 annotation(Placement(transformation(x=-50.0, y=34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP2 annotation(Placement(transformation(x=50.0, y=54.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP3 annotation(Placement(transformation(x=30.0, y=34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP2.C,plateHeatExchanger.Ec) annotation(Line(points={{-60,54},{-20,54}}, color={0,0,255}));
  connect(sourceP3.C,plateHeatExchanger.Ef) annotation(Line(points={{-40,34},{-15,34},{-15,48}}, color={0,0,255}));
  connect(plateHeatExchanger.Sc,puitsP2.C) annotation(Line(points={{0,54.2},{20,54.2},{20,54},{40,54}}, color={0,0,255}));
  connect(plateHeatExchanger.Sf,puitsP3.C) annotation(Line(points={{-5,48},{-6,48},{-6,34},{20,34}}, color={0,0,255}));
end TestStaticWaterWaterExchanger;
