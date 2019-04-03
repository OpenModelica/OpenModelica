within ThermoSysPro.MultiFluids.Machines;
model CHPEngineTriGenPredSystem
  parameter ThermoSysPro.Units.AbsoluteTemperature Tair=298 "Temperature inlet air";
  parameter Real RechFumEff=0.717833 "Flue gases heater efficiency";
  parameter Real RechWaterEff=0.837865 "Water heater efficiency";
  parameter Integer mechanical_efficiency_type=3 "Engine efficiency type" annotation(choices(choice=1 "Fixed nominal efficiency", choice=2 "Efficiency computed using a linear function Coef_Rm", choice=3 "Efficiency computed using the Beau de Rochas Cycle"));
  parameter Real Rmeca_nom=0.4 "Engine nominal efficiency";
  parameter Modelica.SIunits.Power Pnom=500000000.0 "Engine nominal power";
  annotation(Diagram, Icon(coordinateSystem(scale=0.1, extent={{-200,-200},{200,200}}), graphics={Rectangle(extent={{-200,200},{200,-200}}, lineColor={0,0,0}, pattern=LinePattern.Dash, lineThickness=0.5),Rectangle(extent={{-180,-2},{-20,-162}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,223,159}),Polygon(points={{-110,-146},{-96,-128},{-100,-138},{-82,-136},{-98,-142},{-78,-148},{-94,-146},{-110,-158},{-102,-148},{-110,-146}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,0,0}),Polygon(points={{-146,-124},{-146,-82},{-106,-82},{-106,-24},{-100,-32},{-94,-24},{-94,-82},{-52,-82},{-52,-124},{-146,-124}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={159,223,159}),Polygon(lineColor={0,0,255}, points={{-180,-52},{-134,-52},{-134,-28},{-62,-28},{-62,-52},{-20,-52},{-20,-44},{-54,-44},{-54,-20},{-142,-20},{-142,-44},{-180,-44},{-180,-52}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, fillColor={0,0,0}),Rectangle(lineColor={0,0,255}, extent={{20,140},{180,38}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Text(lineColor={0,0,255}, extent={{50,142},{146,74}}, fillColor={0,0,255}, textString="E"),Rectangle(lineColor={0,0,255}, extent={{-180,140},{-20,38}}, fillPattern=FillPattern.Solid, fillColor={95,191,0}),Line(points={{-160,38},{-160,116},{-100,72},{-100,72},{-100,72}}, color={255,0,0}, thickness=1.0),Text(lineColor={0,0,255}, extent={{-148,146},{-52,78}}, fillColor={0,0,255}, textString="E"),Line(points={{38,38},{38,116},{98,72},{158,120},{158,38}}, color={0,0,0}, thickness=1.0),Line(points={{-20,98},{20,98}}, color={0,0,255}, thickness=1.0),Line(points={{-160,-2},{-160,38}}, color={255,0,0}, thickness=1.0),Line(points={{-40,-2},{-40,38}}, color={0,0,255}, thickness=1.0),Polygon(lineColor={0,0,255}, points={{-20,-52},{26,-52},{26,-52},{38,-52},{38,-52},{44,-52},{44,38},{36,38},{36,-44},{18,-44},{18,-44},{-20,-44},{-20,-52}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, fillColor={0,0,0}),Line(points={{-40,38},{-40,116},{-100,72},{-100,72},{-100,72}}, color={0,0,255}, thickness=1.0),Line(points={{40,38},{40,116},{100,72},{160,120},{160,38}}, color={0,0,0}, thickness=1.0),Line(points={{42,38},{42,116},{102,72},{162,120},{162,38}}, color={0,0,0}, thickness=1.0)}), DymolaStoredErrors, Documentation(revisions="<html>
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
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ Source_water(P0=300000.0, Q0=12.2, h0=205000.0) annotation(Placement(transformation(x=51.0, y=-31.0, scale=0.11, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe PDC1(L=0.0001) annotation(Placement(transformation(x=-60.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=-90.0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink Sink_water annotation(Placement(transformation(x=-33.0, y=-60.0, scale=0.11, aspectRatio=1.09090909090909, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.PressureLosses.LumpedStraightPipe PDC2(L=0.0001) annotation(Placement(transformation(x=-80.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0)));
  ThermoSysPro.FlueGases.PressureLosses.SingularPressureLoss silencieux(K=20) annotation(Placement(transformation(x=-39.0, y=16.0, scale=0.09, aspectRatio=1.11111111111111, flipHorizontal=true, flipVertical=true, rotation=90.0)));
  ThermoSysPro.Combustion.BoundaryConditions.FuelSourcePQ Fuel(rho=500, Hum=0, Xh=0.25, Xs=0, Xashes=0, Vol=100, T0=298, Xc=0.75, Xo=0, Xn=0, LHV=47500000.0, Q0=0.156042) annotation(Placement(transformation(x=51.0, y=-7.0, scale=0.11, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.MultiFluids.Machines.AlternatingEngine Engine(DPe=1, MMg=20, Xref=0.3166, Xpth=0, RV=6.45, Kc=1.28, Kd=1.33, Tsf(fixed=false, start=657), exc(fixed=false, start=1.8), mechanical_efficiency_type=mechanical_efficiency_type, Rmeca_nom=Rmeca_nom, Pnom=Pnom) annotation(Placement(transformation(x=0.0, y=0.0, scale=0.24, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.WaterSteam.HeatExchangers.StaticWaterWaterExchangerDTorWorEff ExchangerWaterWater(DPc(start=0.1), DPf(start=0.1), W(fixed=false, start=463400.0), EffEch=RechWaterEff, exchanger_type=3) annotation(Placement(transformation(x=0.0, y=-66.0, scale=0.14, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.MultiFluids.HeatExchangers.StaticExchangerWaterSteamFlueGases ExchangerWaterFlueGases(W(fixed=false, start=1195900.0), EffEch=RechFumEff) annotation(Placement(transformation(x=0.0, y=68.0, scale=0.14, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.FlueGases.BoundaryConditions.SinkG puits_fumees annotation(Placement(transformation(x=70.0, y=68.0, scale=0.12, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Pression(k=100000.0) annotation(Placement(transformation(x=110.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Debit_air(k(fixed=false)=50) annotation(Placement(transformation(x=30.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.BoundaryConditions.SourceG Air(Xco2=0, Xh2o=0.005, Xo2=0.23, Xso2=0) annotation(Placement(transformation(x=60.0, y=20.0, scale=0.12, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Temperature(k=Tair) annotation(Placement(transformation(x=90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI outletWaterSteamI annotation(Placement(transformation(x=200.0, y=100.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=200.0, y=100.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInletI inletWaterSteamI annotation(Placement(transformation(x=-200.0, y=100.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-200.0, y=100.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante Debit_eau(k=12.2) annotation(Placement(transformation(x=88.0, y=-20.0, scale=0.08, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
equation
  connect(Sink_water.C,ExchangerWaterWater.Sc) annotation(Line(points={{-22,-60},{-12.08,-60},{-12.08,-60.4},{-5.74,-60.4}}));
  connect(ExchangerWaterWater.Ec,PDC1.C2) annotation(Line(points={{-5.74,-71.6},{-60,-71.6},{-60,-20}}));
  connect(PDC2.C1,ExchangerWaterWater.Sf) annotation(Line(points={{-80,-20},{-80,-40},{-0.14,-40},{-0.14,-52}}));
  connect(Debit_air.y,Air.IMassFlow) annotation(Line(points={{41,40},{60,40},{60,26}}));
  connect(Air.ITemperature,Temperature.y) annotation(Line(points={{60,14},{60,10},{79,10}}));
  connect(ExchangerWaterWater.Ef,inletWaterSteamI) annotation(Line(points={{9.19104e-16,-80},{0,-80},{0,-100},{-140,-100},{-140,100},{-200,100}}));
  connect(Debit_eau.y,Source_water.IMassFlow) annotation(Line(points={{79.2,-20},{51,-20},{51,-25.5}}));
  connect(puits_fumees.IPressure,Pression.y) annotation(Line(points={{76,68},{90,68},{90,70},{99,70}}));
  connect(silencieux.C2,ExchangerWaterFlueGases.Cfg1) annotation(Line(points={{-39,26},{-39,68},{-12.6,68}}, color={0,0,0}, thickness=1.0));
  connect(ExchangerWaterFlueGases.Cfg2,puits_fumees.C) annotation(Line(points={{12.6,67.93},{36.3,67.93},{36.3,68},{58.24,68}}, color={0,0,0}, thickness=1.0));
  connect(ExchangerWaterFlueGases.Cws2,outletWaterSteamI) annotation(Line(points={{2.63361e-15,82},{2.63361e-15,100},{200,100}}, color={0,0,255}));
  connect(PDC2.C2,ExchangerWaterFlueGases.Cws1) annotation(Line(points={{-80,0},{-80,40},{9.19104e-16,40},{9.19104e-16,54}}, color={0,0,255}));
  connect(PDC1.C1,Engine.Cws2) annotation(Line(points={{-60,0},{-60,32},{1.32262e-15,32},{1.32262e-15,21.6}}));
  connect(Engine.Cair,Air.C) annotation(Line(points={{21.6,9.6},{34,9.6},{34,20},{48,20}}, color={0,0,0}, thickness=1.0));
  connect(Engine.Cws1,Source_water.C) annotation(Line(points={{-1.32262e-15,-21.6},{-1.32262e-15,-31},{40,-31}}));
  connect(silencieux.C1,Engine.Cfg) annotation(Line(points={{-39,6},{-40,6},{-40,1.32262e-15},{-21.6,1.32262e-15}}, color={0,0,0}, thickness=1.0));
  connect(Engine.Cfuel,Fuel.C) annotation(Line(points={{21.6,-9.6},{32,-9.6},{32,-7},{40,-7}}, color={0,0,0}));
end CHPEngineTriGenPredSystem;
