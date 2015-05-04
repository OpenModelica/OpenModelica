within ThermoSysPro.HeatNetworksCooling;
model AbsorptionRefrigeratorSystem "Refrigeration system by absorption"
  parameter Real DesEff=0.362979 "Desorber efficiency";
  parameter Real Pth=0.33 "Desorber thermal losses (0-1 %W)";
  parameter Real ExchEff=0.99 "Exchanger water LiBr efficiency";
  parameter Real EvapEff=0.99 "Evaporator efficiency";
  parameter Modelica.SIunits.MassFlowRate Qsol=8.856 "Solution mass flow rate";
  parameter Modelica.SIunits.MassFlowRate Qnom=8.856 "Pump solution nominal mass flow rate";
  parameter ThermoSysPro.Units.DifferentialPressure DPnom=3386.05 "Pump solution nominal delta pressure";
  annotation(Diagram(coordinateSystem(scale=0.1, extent={{-200,-200},{200,200}}), graphics={Text(lineColor={0,0,255}, extent={{-22,-94},{4,-98}}, fillColor={0,0,255}, textString="Absorber"),Text(lineColor={0,0,255}, extent={{14,-48},{84,-54}}, fillColor={0,0,255}, textString="Water at ambient temperature"),Text(lineColor={0,0,255}, extent={{-44,52},{10,46}}, fillColor={0,0,255}, textString="Water outlet (ambient)"),Text(lineColor={0,0,255}, extent={{-100,50},{-74,46}}, fillColor={0,0,255}, textString="Desorber"),Text(lineColor={0,0,255}, extent={{-122,-4},{-92,-8}}, fillColor={0,0,255}, textString="Heat source"),Text(lineColor={0,0,255}, extent={{-140,-24},{-82,-36}}, fillColor={0,0,255}, textString="Solution heat exchanger"),Text(lineColor={0,0,255}, extent={{-130,-60},{-86,-74}}, fillColor={0,0,255}, textString="Solution expansion"),Text(lineColor={0,0,255}, extent={{-62,-82},{-24,-90}}, fillColor={0,0,255}, textString="Solution pump"),Text(lineColor={0,0,255}, extent={{-2,34},{20,30}}, fillColor={0,0,255}, textString="Condensor"),Text(lineColor={0,0,255}, extent={{46,8},{72,4}}, fillColor={0,0,255}, textString="Evaporator"),Text(lineColor={0,0,255}, extent={{46,-24},{76,-28}}, fillColor={0,0,255}, textString="Cold supply"),Text(lineColor={0,0,255}, extent={{16,126},{58,114}}, fillColor={0,0,255}, textString="Water expansion")}), Icon(coordinateSystem(scale=0.1, extent={{-200,-200},{200,200}}), graphics={Rectangle(extent={{-200,200},{200,-200}}, lineColor={0,191,0}, pattern=LinePattern.Dash, lineThickness=0.5),Polygon(points={{-180,190},{-170,200},{-42,200},{-32,190},{-32,30},{-42,20},{-170,20},{-180,30},{-180,190}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{-32,100},{-32,30},{-42,20},{-170,20},{-180,30},{-180,100},{-132,100},{-110,176},{-42,176},{-42,164},{-98,164},{-80,100},{-32,100}}, lineColor={0,0,0}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(points={{-180,170},{-106,170},{-106,94},{-106,48},{-180,48}}, color={0,0,255}, thickness=0.5),Line(points={{-118,178},{-106,188},{-92,178}}, color={0,0,255}, thickness=0.5),Polygon(points={{-180,-10},{-170,0},{-42,0},{-32,-10},{-32,-170},{-42,-180},{-170,-180},{-180,-170},{-180,-10}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{-32,-100},{-32,-170},{-42,-180},{-170,-180},{-180,-170},{-180,-100},{-132,-100},{-110,-24},{-42,-24},{-42,-36},{-98,-36},{-80,-100},{-32,-100}}, lineColor={0,0,0}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(points={{-170,-30},{-106,-30},{-106,-106},{-106,-152},{-170,-152}}, color={0,0,255}, thickness=0.5),Line(points={{-120,-12},{-106,-22},{-92,-12}}, color={0,0,255}, thickness=0.5),Rectangle(extent={{0,140},{160,40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,223,159}),Line(points={{24,50},{24,128},{82,84},{140,132},{140,50}}, color={0,0,255}, thickness=0.5),Text(lineColor={0,0,255}, extent={{46,82},{114,40}}, fillColor={0,0,0}, textString="Cond"),Rectangle(lineColor={0,0,255}, extent={{0,-40},{160,-160}}, fillPattern=FillPattern.Solid, fillColor={95,191,0}),Line(points={{20,-160},{20,-82},{80,-128},{140,-78},{140,-160}}, color={0,0,255}, thickness=0.5),Text(lineColor={0,0,255}, extent={{38,-46},{120,-104}}, fillColor={0,0,255}, textString="Evap"),Text(lineColor={0,0,255}, extent={{-104,68},{-34,22}}, fillColor={0,0,255}, textString="Des"),Text(lineColor={0,0,255}, extent={{-102,-130},{-32,-176}}, fillColor={0,0,255}, textString="Abs")}), DymolaStoredErrors, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Benoît Bride</li>
</ul>
</html>
"), Diagram(coordinateSystem(scale=0.1, extent={{-200,-200},{200,200}})), Icon(coordinateSystem(scale=0.1, extent={{-200,-200},{200,200}})));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI outletWaterSteamI annotation(Placement(transformation(x=-190.0, y=170.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-190.0, y=170.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInletI inletWaterSteamI annotation(Placement(transformation(x=-190.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-190.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI ColdNeedOutlet annotation(Placement(transformation(x=20.0, y=-170.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=20.0, y=-170.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInletI ColdNeedInlet annotation(Placement(transformation(x=140.0, y=-170.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=140.0, y=-170.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  DesorberWaterLiBr desorber(W(fixed=false, start=4160000.0), DPc=0.2, DTm(fixed=false, start=9.648), Pth=Pth, Ec(h(start=432000.0, fixed=false)), Eff=DesEff) annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.HeatExchangers.ExchangerEfficiency solutionHeatExchanger(Ef(P(fixed=false, start=900)), Qf(fixed=false, start=13), Tsf(fixed=false, start=343.15), DPc=0.2, DPf=0.2, Hsf(fixed=false, start=102586), Xf(fixed=false, start=0.5633), Eff=ExchEff) annotation(Placement(transformation(x=-70.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  ThermoSysPro.WaterSolution.PressureLosses.SingularPressureLoss solutionExp(C2(P(fixed=false, start=870)), K=10) annotation(Placement(transformation(x=-110.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  WaterSolution.Machines.StaticCentrifugalPumpNom solutionPump(Qnom=Qnom, DPnom=DPnom) annotation(Placement(transformation(x=-30.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ ambientSource(P0=100000.0, Q0=313, h0=100000.0) annotation(Placement(transformation(x=50.0, y=-130.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  AbsorberWaterLiBr absorber(DPf=0.2, Sc(T(fixed=false, start=290.98)), DPc(fixed=false, start=0.2)) annotation(Placement(transformation(x=-10.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink ambientSink annotation(Placement(transformation(x=30.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss waterExp(K=2749.77) annotation(Placement(transformation(x=30.0, y=130.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.HeatExchangers.StaticWaterWaterExchangerDTorWorEff evaporator(EffEch=EvapEff) annotation(Placement(transformation(x=70.0, y=-10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  ThermoSysPro.WaterSolution.LoopBreakers.LoopBreakerQ loopBreakerQ annotation(Placement(transformation(x=-30.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  WaterSolution.BoundaryConditions.RefQ solutionMassFlowRate annotation(Placement(transformation(x=-30.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante solutionMassFlowRateValue(k=Qsol) annotation(Placement(transformation(x=0.0, y=0.0, scale=0.06, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser condensor annotation(Placement(transformation(x=30.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=-270.0)));
equation
  connect(desorber.Sf,solutionHeatExchanger.Ec) annotation(Line(points={{-89.8,21},{-89.8,-24},{-76,-24},{-76,-24.2}}, color={0,0,0}));
  connect(solutionHeatExchanger.Sf,desorber.Ef) annotation(Line(points={{-69.8,-40},{-70,-40},{-70,-60},{-50,-60},{-50,36},{-82.6,36}}, color={0,0,0}));
  connect(ambientSource.C,absorber.Ef) annotation(Line(points={{40,-130},{6.4,-130},{6.4,-116.2},{-2.6,-116.2}}, color={0,0,255}));
  connect(solutionExp.C2,absorber.Ec) annotation(Line(points={{-110,-59},{-110,-104},{-17.4,-104}}, color={0,0,0}));
  connect(solutionPump.Ce,absorber.Sc) annotation(Line(points={{-30,-79},{-30,-130},{-10,-130},{-10,-119}}, color={0,0,0}));
  connect(waterExp.C2,evaporator.Ef) annotation(Line(points={{40,130},{70,130},{70,0}}, color={0,0,255}));
  connect(evaporator.Sf,absorber.Evap) annotation(Line(points={{70.1,-20},{70.1,-44},{-10,-44},{-10,-101}}, color={0,0,255}));
  connect(desorber.Svap,condensor.Ec) annotation(Line(points={{-90,39.05},{-90,44},{20,44}}, color={0,0,255}));
  connect(condensor.Sc,waterExp.C1) annotation(Line(points={{20,56},{-10,56},{-10,130},{20,130}}, color={0,0,255}));
  connect(ambientSink.C,condensor.Sf) annotation(Line(points={{30,80},{30,60},{29.9,60}}));
  connect(condensor.Ef,absorber.Sf) annotation(Line(points={{30,40},{30,-104},{-2.8,-104}}));
  connect(outletWaterSteamI,desorber.Sc) annotation(Line(points={{-190,170},{-106,170},{-106,36},{-97.2,36}}, color={255,0,0}));
  connect(inletWaterSteamI,desorber.Ec) annotation(Line(points={{-190,50},{-110,50},{-110,23.8},{-97.4,23.8}}));
  connect(evaporator.Ec,ColdNeedInlet) annotation(Line(points={{74.1,-6},{160,-6},{160,-170},{140,-170}}));
  connect(ColdNeedOutlet,evaporator.Sc) annotation(Line(points={{20,-170},{100,-170},{100,-14},{74.1,-14}}, color={255,0,0}));
  connect(solutionHeatExchanger.Ef,solutionMassFlowRate.C2) annotation(Line(points={{-69.8,-20},{-70,-20},{-70,20},{-30,20},{-30,10}}, color={0,0,0}));
  connect(solutionMassFlowRate.C1,loopBreakerQ.Cs) annotation(Line(points={{-30,-10},{-30,-20}}, color={0,0,0}));
  connect(solutionExp.C1,solutionHeatExchanger.Sc) annotation(Line(points={{-110,-41},{-110,-35.8},{-76,-35.8}}, color={0,0,0}));
  connect(loopBreakerQ.Ce,solutionPump.Cs) annotation(Line(points={{-30,-40},{-30,-50},{-35,-50},{-35,-61}}, color={0,0,0}));
  connect(solutionMassFlowRate.IMassFlow,solutionMassFlowRateValue.y) annotation(Line(points={{-19,6.73556e-16},{-12.5,6.73556e-16},{-12.5,0},{-6.6,0}}));
end AbsorptionRefrigeratorSystem;
