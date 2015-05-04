within ThermoSysPro.MultiFluids.HeatExchangers;
model SimpleEvaporatorWaterSteamFlueGases "Simple water/steam - flue gases evaporator"
  parameter Real Kdpf=10 "Flue gases pressure drop coefficient";
  parameter Real Kdpe=10 "Water/steam pressure drop coefficient";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure Pef(start=300000.0) "Flue gases pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Psf(start=250000.0) "Flue gases pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tef(start=600) "Flue gases temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsf(start=400) "Flue gases temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hsf(start=300000.0) "Flue gases specific enthalpy at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hef(start=600000.0) "Flue gases specific enthalpy at the inlet";
  Modelica.SIunits.MassFlowRate Qf(start=10) "Flue gases mass flow rate";
  ThermoSysPro.Units.AbsolutePressure Pee(start=2000000.0) "Water pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Pse(start=2000000.0) "Water pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tee(start=400) "Water temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tse(start=450) "Water temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hee(start=300000.0) "Water specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hse(start=2000000.0) "Water specific enthalpy at the outlet";
  Modelica.SIunits.MassFlowRate Qe(start=10) "Water mass flow rate";
  Modelica.SIunits.Density rhof(start=0.9) "Flue gases density";
  Modelica.SIunits.Density rhoe(start=700) "Water density";
  Modelica.SIunits.Power W(start=100000000.0) "Power exchanged";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,80},{100,-80}}, lineColor={0,0,255}, lineThickness=0.5, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Text(lineColor={0,0,255}, extent={{-30,76},{28,66}}, fillColor={0,0,0}, lineThickness=0.5, textString="Flue gases"),Polygon(points={{-94,12},{-80,12},{-80,56},{80,56},{80,12},{92,12},{92,6},{74,6},{74,50},{-74,50},{-74,6},{-94,6},{-94,12}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Polygon(points={{-94,-12},{-80,-12},{-80,-56},{80,-56},{80,-12},{92,-12},{92,-6},{74,-6},{74,-50},{-74,-50},{-74,-6},{-94,-6},{-94,-12}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{-114,28},{-48,18}}, fillColor={0,0,0}, lineThickness=0.5, textString="Water/Steam"),Polygon(points={{-94,3},{90,3},{90,-3},{-94,-3},{-94,3}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Solid)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,80},{100,-80}}, lineColor={0,0,255}, lineThickness=0.5, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Polygon(points={{-94,12},{-80,12},{-80,56},{80,56},{80,12},{92,12},{92,6},{74,6},{74,50},{-74,50},{-74,6},{-94,6},{-94,12}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Polygon(points={{-92,3},{92,3},{92,-3},{-92,-3},{-92,3}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{-94,-12},{-80,-12},{-80,-56},{80,-56},{80,-12},{92,-12},{92,-6},{74,-6},{74,-50},{-74,-50},{-74,-6},{-94,-6},{-94,-12}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0})}), Documentation(revisions="<html>
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
"));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cws2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Cws1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Cfg1 annotation(Placement(transformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Cfg2 annotation(Placement(transformation(x=0.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proee annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proes annotation(Placement(transformation(x=-42.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proem annotation(Placement(transformation(x=-66.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation(Placement(transformation(x=90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation(Placement(transformation(x=68.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=1.0 "Small number for pressure loss equation";
equation
  Pef=Cfg1.P;
  Tef=Cfg1.T;
  Qf=Cfg1.Q;
  Psf=Cfg2.P;
  Tsf=Cfg2.T;
  Cfg1.Q=Cfg2.Q;
  Cfg2.Xco2=Cfg1.Xco2;
  Cfg2.Xh2o=Cfg1.Xh2o;
  Cfg2.Xo2=Cfg1.Xo2;
  Cfg2.Xso2=Cfg1.Xso2;
  Pee=Cws1.P;
  Hee=Cws1.h;
  Qe=Cws1.Q;
  Pse=Cws2.P;
  Hse=Cws2.h;
  Cws1.Q=Cws2.Q;
  0=if Qe > 0 then Cws1.h - Cws1.h_vol else Cws2.h - Cws2.h_vol;
  Pef=Psf + Kdpf*ThermoSysPro.Functions.ThermoSquare(Qf, eps)/rhof;
  Pee=Pse + Kdpe*ThermoSysPro.Functions.ThermoSquare(Qe, eps)/rhoe;
  W=Qf*(Hef - Hsf);
  W=Qe*(Hse - Hee);
  Hef=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pef, Tef, Cfg1.Xco2, Cfg1.Xh2o, Cfg1.Xo2, Cfg1.Xso2);
  Hsf=ThermoSysPro.Properties.FlueGases.FlueGases_h(Psf, Tsf, Cfg1.Xco2, Cfg1.Xh2o, Cfg1.Xo2, Cfg1.Xso2);
  rhof=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pef, Tef, Cfg1.Xco2, Cfg1.Xh2o, Cfg1.Xo2, Cfg1.Xso2);
  proee=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pee, Hee, mode);
  Tee=proee.T;
  proem=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Pee + Pse)/2, (Hee + Hse)/2, mode);
  rhoe=proem.d;
  proes=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pse, Hse, mode);
  Tse=proes.T;
  (lsat,vsat)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(Pse);
  Hse=vsat.h;
end SimpleEvaporatorWaterSteamFlueGases;
