within ThermoSysPro.Examples.SimpleExamples;
model TestSimpleEvaporatorWaterSteamFlueGases
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink puits_Eau annotation(Placement(transformation(x=74.0, y=-7.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.MultiFluids.HeatExchangers.SimpleEvaporatorWaterSteamFlueGases EchangeurEfficacite(Kdpf=1, Kdpe=1) annotation(Placement(transformation(x=0.0, y=-7.0, scale=0.44, aspectRatio=0.636363636363636, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ source_Eau(P0=6527000.0, Q0=38.92/3.6, h0=1242080) annotation(Placement(transformation(x=-74.0, y=-7.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.BoundaryConditions.SourcePQ Source_Fumees(Xso2=0, P0=101000.0, Q0=86.7429, T0=750.54, Xco2=0.04725, Xh2o=0.051874, Xo2=0.15011) annotation(Placement(transformation(x=-17.0, y=60.0, scale=0.17, aspectRatio=0.882352941176471, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  ThermoSysPro.FlueGases.BoundaryConditions.Sink Puits_Fumees annotation(Placement(transformation(x=16.0, y=-70.0, scale=0.16, aspectRatio=0.9375, flipHorizontal=true, flipVertical=false, rotation=-180.0)));
equation
  connect(Source_Fumees.C,EchangeurEfficacite.Cfg1) annotation(Line(points={{0,60},{0,18.2}}, color={0,0,0}, thickness=1.0));
  connect(EchangeurEfficacite.Cfg2,Puits_Fumees.C) annotation(Line(points={{0,-32.2},{0,-70},{0.32,-70}}, color={0,0,0}, thickness=1.0));
  connect(EchangeurEfficacite.Cws2,puits_Eau.C) annotation(Line(points={{44,-7},{54,-7},{54,-7},{64,-7}}, color={0,0,255}));
  connect(EchangeurEfficacite.Cws1,source_Eau.C) annotation(Line(points={{-44,-7},{-54,-7},{-54,-7},{-64,-7}}));
end TestSimpleEvaporatorWaterSteamFlueGases;
