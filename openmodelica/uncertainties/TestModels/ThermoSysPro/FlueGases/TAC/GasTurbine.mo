within ThermoSysPro.FlueGases.TAC;
model GasTurbine "Combustion turbine for CICO and Barilla plants"
  parameter Real comp_tau_n=15 "Nominal compression nominal rate";
  parameter Real comp_eff_n=0.9 "Compressor nominal efficiency";
  parameter Real A0=0.1725914;
  parameter Real A1=1.46222;
  parameter Real A2=-0.634857;
  parameter Real A3=0;
  parameter Real A4=0;
  parameter Real exp_tau_n=0.05 "Turbine nominal expansion rate";
  parameter Real exp_eff_n=0.9 "Turbine nominal efficiency";
  parameter Real TurbQred=0.01 "Turbine reduced mass flow rate";
  parameter Real B0=0.3735955;
  parameter Real B1=1.42460674;
  parameter Real B2=-0.80865168;
  parameter Real Kcham=1 "Chamber pressure loss coefficient";
  parameter Modelica.SIunits.Power Wpth=100000.0 "Combustion chamber thermal losses";
  annotation(Diagram, Icon(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-100,72},{-100,-70},{-20,-20},{-20,20},{-100,72}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={191,255,127}),Rectangle(extent={{-20,20},{20,-20}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={159,223,223}),Polygon(points={{20,20},{20,-20},{100,-70},{100,70},{20,20}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={127,255,127}),Line(points={{-60,96},{-60,60},{-10,60},{-10,20}}, color={0,0,255}),Line(points={{60,96},{60,60},{8,60},{8,20}}, color={0,0,191})}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"), Diagram(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}})), Icon(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}})));
  BoundaryConditions.AirHumidity xAIR annotation(Placement(transformation(x=-84.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-270.0)));
  ThermoSysPro.FlueGases.Machines.Compressor Compresseur(A4=A4, A3=A3, A2=A2, A1=A1, A0=A0, tau_n=comp_tau_n, is_eff_n=comp_eff_n) annotation(Placement(transformation(x=-57.0, y=0.0, scale=0.208333333333333, aspectRatio=0.933333333333333, flipHorizontal=false, flipVertical=false)));
  Combustion.CombustionChambers.GTCombustionChamber chambreCombustionTAC(Acham=1, eta_comb=1, kcham=Kcham, Pea(start=1380000.0), Wpth=Wpth, Qsf(start=500), Qfuel(start=10), Psf(start=1320000.0), Tsf(start=1495)) annotation(Placement(transformation(x=0.0, y=57.0, scale=0.25, aspectRatio=1.04, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Machines.CombustionTurbine TurbineAgaz(Te(start=1495), Pe(start=1320000.0), A2=B2, A1=B1, A0=B0, tau_n=exp_tau_n, Qred=TurbQred, Ps(fixed=false, start=101300.0), is_eff_n=exp_eff_n, Ts(start=894.518, fixed=false)) annotation(Placement(transformation(x=63.0, y=0.0, scale=0.16, aspectRatio=1.375, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesInletI Entree_air annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesOutletI Sortie_fumees annotation(Placement(transformation(x=100.0, y=0.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInletI Entree_eau_combustion annotation(Placement(transformation(x=-60.0, y=100.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-60.0, y=100.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Combustion.Connectors.FuelInletI Entree_combustible annotation(Placement(transformation(x=60.0, y=100.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=60.0, y=100.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Huminide annotation(Placement(transformation(x=-104.0, y=60.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-104.0, y=60.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal PuissanceMeca annotation(Placement(transformation(x=104.0, y=-40.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0), iconTransformation(x=104.0, y=-40.0, scale=0.04, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
equation
  connect(Huminide,xAIR.humidity) annotation(Line(points={{-104,60},{-56,60},{-56,30},{-73,30}}, color={0,0,255}));
  connect(TurbineAgaz.MechPower,PuissanceMeca) annotation(Line(points={{80.6,-19.8},{90,-19.8},{90,-40},{104,-40}}, color={0,0,255}));
  connect(Compresseur.Power,TurbineAgaz.CompressorPower) annotation(Line(points={{-38.25,-8.4},{46,-8.4},{46,-8},{45.4,-8.8}}));
  connect(xAIR.C2,Compresseur.Ce) annotation(Line(points={{-84,20},{-84,3.55271e-15},{-75.75,3.55271e-15}}, color={0,0,0}, thickness=1.0));
  connect(TurbineAgaz.Cs,Sortie_fumees) annotation(Line(points={{79,0},{100,0}}, color={0,0,0}, thickness=1.0));
  connect(xAIR.C1,Entree_air) annotation(Line(points={{-84,40},{-100,40},{-100,0}}, color={0,0,0}, thickness=1.0));
  connect(Compresseur.Cs,chambreCombustionTAC.Ca) annotation(Line(points={{-38.25,3.55271e-15},{-32,3.55271e-15},{-32,57},{-22.5,57}}, color={0,0,0}, thickness=1.0));
  connect(chambreCombustionTAC.Cfg,TurbineAgaz.Ce) annotation(Line(points={{22.5,57},{32,57},{32,0},{47,0}}, color={0,0,0}, thickness=1.0));
  connect(Entree_eau_combustion,chambreCombustionTAC.Cws) annotation(Line(points={{-60,100},{-60,90},{-15,90},{-15,80.4}}));
  connect(chambreCombustionTAC.Cfuel,Entree_combustible) annotation(Line(points={{0,33.6},{0,20},{60,20},{60,100}}, color={0,0,0}));
end GasTurbine;
