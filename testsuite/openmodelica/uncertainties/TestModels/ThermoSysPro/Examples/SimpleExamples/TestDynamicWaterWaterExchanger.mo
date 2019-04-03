within ThermoSysPro.Examples.SimpleExamples;
model TestDynamicWaterWaterExchanger
  ThermoSysPro.WaterSteam.HeatExchangers.DynamicWaterWaterExchanger echangeurAPlaques1D(modec=1, modef=1, N=5) annotation(Placement(transformation(x=-10.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP(T0=340) annotation(Placement(transformation(x=-70.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP1 annotation(Placement(transformation(x=-50.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP annotation(Placement(transformation(x=50.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP puitsP1 annotation(Placement(transformation(x=30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceP.C,echangeurAPlaques1D.Ec) annotation(Line(points={{-60,50},{-20,50}}, color={0,0,255}));
  connect(sourceP1.C,echangeurAPlaques1D.Ef) annotation(Line(points={{-40,30},{-15,30},{-15,44}}, color={0,0,255}));
  connect(echangeurAPlaques1D.Sc,puitsP.C) annotation(Line(points={{0,50.2},{20,50.2},{20,50},{40,50}}, color={0,0,255}));
  connect(echangeurAPlaques1D.Sf,puitsP1.C) annotation(Line(points={{-5,44},{-6,44},{-6,30},{20,30}}, color={0,0,255}));
end TestDynamicWaterWaterExchanger;
