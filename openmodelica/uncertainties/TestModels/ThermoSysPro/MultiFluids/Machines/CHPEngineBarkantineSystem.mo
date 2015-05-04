within ThermoSysPro.MultiFluids.Machines;
model CHPEngineBarkantineSystem
  parameter ThermoSysPro.Units.AbsoluteTemperature Tair=300 "Temperature inlet air";
  parameter Real RechFumEff=0.73 "Flue gases heater efficiency";
  parameter Real RechWaterEff=0.9 "Water heater efficiency";
  parameter Integer mechanical_efficiency_type=3 "Engine efficiency type" annotation(choices(choice=1 "Fixed nominal efficiency", choice=2 "Efficiency computed using a linear function Coef_Rm", choice=3 "Efficiency computed using the Beau de Rochas Cycle"));
  parameter Real Rmeca_nom=0.4 "Engine nominal efficiency";
  parameter Modelica.SIunits.Power Pnom=1400000.0 "Engine nominal power";
  annotation(Diagram, Icon(coordinateSystem(scale=0.1, extent={{-200,-200},{200,200}}), graphics={Rectangle(extent={{-200,200},{200,-200}}, lineColor={0,0,0}, pattern=LinePattern.Dash, lineThickness=0.5),Rectangle(extent={{-180,0},{-20,-160}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,223,159}),Polygon(points={{-110,-144},{-96,-126},{-100,-136},{-82,-134},{-98,-140},{-78,-146},{-94,-144},{-110,-156},{-102,-146},{-110,-144}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,0,0}),Polygon(points={{-146,-122},{-146,-80},{-106,-80},{-106,-22},{-100,-30},{-94,-22},{-94,-80},{-52,-80},{-52,-122},{-146,-122}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={159,223,159}),Polygon(lineColor={0,0,255}, points={{-180,-50},{-134,-50},{-134,-26},{-62,-26},{-62,-50},{-20,-50},{-20,-42},{-54,-42},{-54,-18},{-142,-18},{-142,-42},{-180,-42},{-180,-50}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, fillColor={0,0,0}),Rectangle(lineColor={0,0,255}, extent={{20,142},{180,40}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Text(lineColor={0,0,255}, extent={{50,144},{146,76}}, fillColor={0,0,255}, textString="E"),Rectangle(lineColor={0,0,255}, extent={{-180,142},{-20,40}}, fillPattern=FillPattern.Solid, fillColor={95,191,0}),Line(points={{-160,40},{-160,118},{-100,74},{-100,74},{-100,74}}, color={255,0,0}, thickness=1.0),Text(lineColor={0,0,255}, extent={{-148,148},{-52,80}}, fillColor={0,0,255}, textString="E"),Line(points={{38,40},{38,118},{98,74},{158,122},{158,40}}, color={0,0,0}, thickness=1.0),Line(points={{-20,100},{20,100}}, color={0,0,255}, thickness=1.0),Line(points={{-160,0},{-160,40}}, color={255,0,0}, thickness=1.0),Line(points={{-40,0},{-40,40}}, color={0,0,255}, thickness=1.0),Polygon(lineColor={0,0,255}, points={{-20,-50},{26,-50},{26,-50},{38,-50},{38,-50},{44,-50},{44,40},{36,40},{36,-42},{18,-42},{18,-42},{-20,-42},{-20,-50}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, fillColor={0,0,0}),Line(points={{-40,40},{-40,118},{-100,74},{-100,74},{-100,74}}, color={0,0,255}, thickness=1.0),Line(points={{40,40},{40,118},{100,74},{160,122},{160,40}}, color={0,0,0}, thickness=1.0),Line(points={{42,40},{42,118},{102,74},{162,122},{162,40}}, color={0,0,0}, thickness=1.0)}), DymolaStoredErrors, Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Guillaume Larrignon</li>
<li>
    Bruno Péchiné</li>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"), Diagram(coordinateSystem(scale=0.1, extent={{-200,-200},{200,200}})), Icon(coordinateSystem(scale=0.1, extent={{-200,-200},{200,200}})));
  ThermoSysPro.Combustion.BoundaryConditions.FuelSourcePQ Fuel(Hum=0, Xh=0.25, Xs=0, Xashes=0, Vol=100, Xc=0.75, Xo=0, Xn=0, T0=299, P0=225000.0, rho=0.72, LHV=48000000.0, Q0=0.0727958) annotation(Placement(transformation(x=50.0, y=-14.0, scale=0.12, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ Source_water(P0=300000.0, h0=293000.0, Q0=11.8) annotation(Placement(transformation(x=51.0, y=-35.0, scale=0.11, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.MultiFluids.Machines.AlternatingEngine Engine(DPe=1, MMg=20, Kd=1.33, Wcomb(fixed=false, start=3494200.0), exc(fixed=false, start=1.8), RV=6.45, Kc=1.28, Xpth=0.01, Xref=0.2896, Tsf(fixed=false, start=815), Wmeca(fixed=false, start=1400000.0), mechanical_efficiency_type=mechanical_efficiency_type, Rmeca_nom=Rmeca_nom, Pnom=Pnom) annotation(Placement(transformation(x=0.0, y=0.0, scale=0.24, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.WaterSteam.HeatExchangers.StaticWaterWaterExchangerDTorWorEff ExchangerWaterWater(EffEch=RechWaterEff, exchanger_type=3) annotation(Placement(transformation(x=0.0, y=-66.0, scale=0.14, aspectRatio=1.0, flipHorizontal=true, flipVertical=true, rotation=90.0)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe PDC1(L=0.0001) annotation(Placement(transformation(x=-60.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=-90.0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink M1_puits_eau annotation(Placement(transformation(x=-31.0, y=-60.0, scale=0.11, aspectRatio=1.09090909090909, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe PDC2(L=0.0001) annotation(Placement(transformation(x=-80.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0)));
  ThermoSysPro.MultiFluids.HeatExchangers.StaticExchangerWaterSteamFlueGases ExchangerWaterFlueGases(Tsf(fixed=false, start=363), EffEch=RechFumEff) annotation(Placement(transformation(x=0.0, y=70.0, scale=0.14, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=270.0)));
  ThermoSysPro.FlueGases.PressureLosses.SingularPressureLoss silencieux(K=20) annotation(Placement(transformation(x=-39.0, y=16.0, scale=0.09, aspectRatio=1.11111111111111, flipHorizontal=true, flipVertical=true, rotation=90.0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI outletWaterSteamI annotation(Placement(transformation(x=200.0, y=100.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=200.0, y=100.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInletI inletWaterSteamI annotation(Placement(transformation(x=-200.0, y=100.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-200.0, y=100.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.BoundaryConditions.SinkG M_puits_fumees annotation(Placement(transformation(x=70.0, y=70.0, scale=0.12, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Pression(k=100000.0) annotation(Placement(transformation(x=110.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.FlueGases.BoundaryConditions.SourceG M_Air(Xco2=0, Xh2o=0.005, Xo2=0.23, Xso2=0) annotation(Placement(transformation(x=52.0, y=14.0, scale=0.12, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Temperature(k=Tair) annotation(Placement(transformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante DebitAir(k=50) annotation(Placement(transformation(x=30.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Debit_eau(k=11.8) annotation(Placement(transformation(x=88.0, y=-26.0, scale=0.08, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
equation
  connect(ExchangerWaterWater.Ef,inletWaterSteamI) annotation(Line(points={{-9.19104e-16,-80},{0,-80},{0,-100},{-140,-100},{-140,100},{-200,100}}));
  connect(M1_puits_eau.C,ExchangerWaterWater.Sc) annotation(Line(points={{-20,-60},{-13.04,-60},{-13.04,-60.4},{-5.74,-60.4}}));
  connect(PDC2.C1,ExchangerWaterWater.Sf) annotation(Line(points={{-80,-20},{-80,-40},{-0.14,-40},{-0.14,-52}}));
  connect(PDC1.C2,ExchangerWaterWater.Ec) annotation(Line(points={{-60,-20},{-60,-71.6},{-5.74,-71.6}}, color={0,0,255}));
  connect(Pression.y,M_puits_fumees.IPressure) annotation(Line(points={{99,70},{76,70}}));
  connect(DebitAir.y,M_Air.IMassFlow) annotation(Line(points={{41,40},{52,40},{52,20}}));
  connect(M_Air.ITemperature,Temperature.y) annotation(Line(points={{52,8},{52,0},{79,0}}));
  connect(Source_water.IMassFlow,Debit_eau.y) annotation(Line(points={{51,-29.5},{51,-26},{79.2,-26}}));
  connect(silencieux.C2,ExchangerWaterFlueGases.Cfg1) annotation(Line(points={{-39,26},{-39,70},{-12.6,70}}, color={0,0,0}, thickness=1.0));
  connect(ExchangerWaterFlueGases.Cfg2,M_puits_fumees.C) annotation(Line(points={{12.6,69.93},{35.3,69.93},{35.3,70},{58.24,70}}, color={0,0,0}, thickness=1.0));
  connect(ExchangerWaterFlueGases.Cws2,outletWaterSteamI) annotation(Line(points={{-7.95401e-16,84},{0,84},{0,100},{200,100}}, color={0,0,255}));
  connect(PDC2.C2,ExchangerWaterFlueGases.Cws1) annotation(Line(points={{-80,0},{-80,48},{4.34812e-15,48},{4.34812e-15,56}}, color={0,0,255}));
  connect(silencieux.C1,Engine.Cfg) annotation(Line(points={{-39,6},{-40,6},{-40,1.32262e-15},{-21.6,1.32262e-15}}, color={0,0,0}, thickness=1.0));
  connect(Engine.Cws1,Source_water.C) annotation(Line(points={{-1.32262e-15,-21.6},{-1.32262e-15,-35},{40,-35}}));
  connect(Engine.Cair,M_Air.C) annotation(Line(points={{21.6,9.6},{32,9.6},{32,14},{40,14}}, color={0,0,0}, thickness=1.0));
  connect(PDC1.C1,Engine.Cws2) annotation(Line(points={{-60,0},{-60,32},{1.32262e-15,32},{1.32262e-15,21.6}}));
  connect(Engine.Cfuel,Fuel.C) annotation(Line(points={{21.6,-9.6},{32,-9.6},{32,-14},{38,-14}}, color={0,0,0}));
end CHPEngineBarkantineSystem;
