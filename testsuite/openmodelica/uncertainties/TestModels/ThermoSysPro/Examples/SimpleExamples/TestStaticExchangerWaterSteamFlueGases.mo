within ThermoSysPro.Examples.SimpleExamples;
model TestStaticExchangerWaterSteamFlueGases
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink puits_Eau annotation(Placement(transformation(x=70.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram);
  ThermoSysPro.MultiFluids.HeatExchangers.StaticExchangerWaterSteamFlueGases EchangeurEfficacite(EffEch=0.9, Kdpf=10, Kdpe=100, W0=1000000.0, exchanger_conf=1, exchanger_type=1) annotation(Placement(transformation(x=0.0, y=0.0, scale=0.4, aspectRatio=0.5, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ source_Eau(P0=400000.0, h0=170000, Q0=15) annotation(Placement(transformation(x=-70.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.BoundaryConditions.SourcePQ Source_Fumees(Xco2=0, Xo2=0.233, Xso2=0, Xh2o=0.01, Q0=20, T0=700, P0=1300000.0) annotation(Placement(transformation(x=-30.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  ThermoSysPro.FlueGases.BoundaryConditions.Sink Puits_Fumees annotation(Placement(transformation(x=30.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-180.0)));
equation
  connect(source_Eau.C,EchangeurEfficacite.Cws1) annotation(Line(points={{-60,0},{-40,0}}, color={0,0,255}));
  connect(EchangeurEfficacite.Cws2,puits_Eau.C) annotation(Line(points={{40,0},{60,0}}, color={0,0,255}));
  connect(Source_Fumees.C,EchangeurEfficacite.Cfg1) annotation(Line(points={{-20,50},{0,50},{0,18}}, color={0,0,0}, thickness=1.0));
  connect(Puits_Fumees.C,EchangeurEfficacite.Cfg2) annotation(Line(points={{20.2,-50},{-0.2,-50},{-0.2,-18}}, color={0,0,0}, thickness=1.0));
end TestStaticExchangerWaterSteamFlueGases;
