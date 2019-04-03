within ThermoSysPro.Examples.SimpleExamples;
model TestStaticWaterWaterExchangerDTorWorEff
  annotation(Diagram);
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceQ sourceWaterSteam_FF(C(P(start=21900000.0)), Q0=481.07, h0=1067900.0) annotation(Placement(transformation(x=-50.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkWaterSteam_FF(P0=21768000.0) annotation(Placement(transformation(x=30.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourceQ sourceWaterSteam_FC(C(P(start=2400000.0)), Q0=23.377, h0=3420300.0) annotation(Placement(transformation(x=-30.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-180.0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkWaterSteam_FC(P0=2413000.0) annotation(Placement(transformation(x=9.0, y=30.0, scale=0.11, aspectRatio=0.909090909090909, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  ThermoSysPro.WaterSteam.HeatExchangers.StaticWaterWaterExchangerDTorWorEff exchangerWaterSteamDTorWorEFF(EffEch=1, Kf=597.832, Ec(P(start=2300000.0)), Ef(P(start=21900000.0)), exchanger_type=3) annotation(Placement(transformation(x=-10.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  connect(sourceWaterSteam_FF.C,exchangerWaterSteamDTorWorEFF.Ef) annotation(Line(points={{-40,-10},{-20,-10}}, color={0,0,255}));
  connect(exchangerWaterSteamDTorWorEFF.Sf,sinkWaterSteam_FF.C) annotation(Line(points={{0,-9.9},{10.2,-9.9},{10.2,-10},{20,-10}}, color={0,0,255}));
  connect(sourceWaterSteam_FC.C,exchangerWaterSteamDTorWorEFF.Ec) annotation(Line(points={{-20,30},{-14,30},{-14,-5.9}}, color={0,0,255}));
  connect(exchangerWaterSteamDTorWorEFF.Sc,sinkWaterSteam_FC.C) annotation(Line(points={{-6,-5.9},{-6,30},{-2,30}}, color={0,0,255}));
end TestStaticWaterWaterExchangerDTorWorEff;
