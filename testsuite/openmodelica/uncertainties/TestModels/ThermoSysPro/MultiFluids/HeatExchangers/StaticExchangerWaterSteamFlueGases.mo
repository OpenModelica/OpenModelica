within ThermoSysPro.MultiFluids.HeatExchangers;
model StaticExchangerWaterSteamFlueGases "Static heat exchanger water/steam - flue gases"
  parameter Integer exchanger_type=1 "Exchanger type - 1: Delta temperature is fixed - 2: delta power is fixed - 3: heat transfer is fixed";
  parameter Real EffEch=0.9 "Thermal exchange efficiency";
  parameter Modelica.SIunits.Power W0=0 "Power exchanged (active if exchanger_type=2)";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer K=100 "Global heat transfer coefficient (active if exchanger_type=3)";
  parameter Modelica.SIunits.Area S=10 "Global heat exchange surface (active if exchanger_type=3)";
  parameter Real Kdpf=10 "Pressure loss coefficient on the flue gas side";
  parameter Real Kdpe=10 "Pressure loss coefficient on the water/steam side";
  parameter Integer exchanger_conf=1 "Exchanger configuration - 1: counter-current. 2: co-current";
  parameter Integer mode=0 "IF97 region of the water. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure Pef(start=300000.0) "Flue gas pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Psf(start=250000.0) "Flue gas pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tef(start=600) "Flue gas temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsf(start=400) "Flue gas temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hef(start=600000.0) "Flue gas specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hsf(start=300000.0) "Flue gas specific enthalpy at the outlet";
  Modelica.SIunits.MassFlowRate Qf(start=10) "Flue gas mass flow rate";
  ThermoSysPro.Units.AbsolutePressure Pee(start=2000000.0) "Water pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Pse(start=2000000.0) "Water pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tee(start=400) "Water temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tse(start=450) "Water temperature at the outlet";
  ThermoSysPro.Units.DifferentialTemperature DT1 "Delta T at the inlet";
  ThermoSysPro.Units.DifferentialTemperature DT2 "Delta T at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hse(start=2000000.0) "Water specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hee(start=300000.0) "Water specific enthalpy at the outlet";
  Modelica.SIunits.MassFlowRate Qe(start=10) "Water mass flow rate";
  Modelica.SIunits.Density rhoe(start=700) "Water density";
  Modelica.SIunits.Density rhof(start=0.9) "Fluie gas density";
  Modelica.SIunits.SpecificHeatCapacity Cpf(start=1000) "Flue gas specific heat capacity";
  Modelica.SIunits.SpecificHeatCapacity Cpe(start=4200) "Water specific heat capacity";
  Modelica.SIunits.Power W(start=100000000.0) "Exchanger power";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,50},{100,-50}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Rectangle(extent={{-100,-50},{100,-80}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Rectangle(extent={{-100,80},{100,50}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(points={{-94,-2},{-44,-2},{-24,46},{16,-48},{36,-2},{90,-2}}, color={0,0,0}, thickness=0.5),Text(lineColor={0,0,255}, extent={{-28,72},{34,56}}, textString="HotFlueGases", fillColor={0,0,0}, lineThickness=0.5),Text(lineColor={0,0,255}, extent={{-34,8},{42,-6}}, fillColor={0,0,0}, lineThickness=0.5, textString="WaterSteam"),Text(lineColor={0,0,255}, extent={{-30,-58},{32,-74}}, textString="HotFlueGases", fillColor={0,0,0}, lineThickness=0.5)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,80},{100,50}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Rectangle(extent={{-100,50},{100,-50}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Line(points={{-94,-2},{-44,-2},{-24,46},{16,-48},{36,-2},{90,-2}}, color={0,0,0}, thickness=0.5),Text(lineColor={0,0,255}, extent={{-34,8},{42,-6}}, fillColor={0,0,0}, lineThickness=0.5, textString="WaterSteam"),Rectangle(extent={{-100,-50},{100,-80}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Text(lineColor={0,0,255}, extent={{-30,-58},{32,-74}}, textString="HotFlueGases", fillColor={0,0,0}, lineThickness=0.5),Text(lineColor={0,0,255}, extent={{-30,72},{32,56}}, textString="HotFlueGases", fillColor={0,0,0}, lineThickness=0.5)}), Documentation(revisions="<html>
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
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cws2 "Water outlet" annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Cws1 "Water inlet" annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Cfg1 annotation(Placement(transformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Cfg2 annotation(Placement(transformation(x=-0.5, y=-90.0, scale=0.105, aspectRatio=0.952380952380952, flipHorizontal=false, flipVertical=false), iconTransformation(x=-0.5, y=-90.0, scale=0.105, aspectRatio=0.952380952380952, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proee annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proes annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proem annotation(Placement(transformation(x=70.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=1.0 "Small number for pressure loss equation";
equation
  Pef=Cfg1.P;
  Tef=Cfg1.T;
  Qf=Cfg1.Q;
  Psf=Cfg2.P;
  Tsf=Cfg2.T;
  Qf=Cfg2.Q;
  Cfg2.Xco2=Cfg1.Xco2;
  Cfg2.Xh2o=Cfg1.Xh2o;
  Cfg2.Xo2=Cfg1.Xo2;
  Cfg2.Xso2=Cfg1.Xso2;
  Pee=Cws1.P;
  Hee=Cws1.h;
  Qe=Cws1.Q;
  Pse=Cws2.P;
  Hse=Cws2.h;
  Qe=Cws2.Q;
  0=if Qe > 0 then Cws1.h - Cws1.h_vol else Cws2.h - Cws2.h_vol;
  if exchanger_conf == 1 then
    DT1=Tef - Tse;
    DT2=Tsf - Tee;
  elseif exchanger_conf == 2 then
    DT1=Tef - Tee;
    DT2=Tsf - Tse;
  else
    DT1=0;
    DT2=0;
    assert(false, "StaticExchangerFlueGasesWaterSteam: incorrect exchanger configuration");
  end if;
  if exchanger_type == 1 then
    W=noEvent(min(Qe*Cpe, Qf*Cpf))*EffEch*(Tef - Tee);
    W=Qf*(Hef - Hsf);
    W=Qe*(Hse - Hee);
  elseif exchanger_type == 2 then
    W=W0;
    W=Qf*(Hef - Hsf);
    W=Qe*(Hse - Hee);
  else
    DT2=if exchanger_conf == 1 then DT1*Modelica.Math.exp(-K*S*(1/(Qf*Cpf) - 1/(Qe*Cpe))) else DT1*Modelica.Math.exp(-K*S*(1/(Qf*Cpf) + 1/(Qe*Cpe)));
    W=Qf*Cpf*(Tef - Tsf);
    W=Qe*(Hse - Hee);
  end if;
  Pef=Psf + Kdpf*ThermoSysPro.Functions.ThermoSquare(Qf, eps)/rhof;
  Pee=Pse + Kdpe*ThermoSysPro.Functions.ThermoSquare(Qe, eps)/rhoe;
  Hef=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pef, Tef, Cfg1.Xco2, Cfg1.Xh2o, Cfg1.Xo2, Cfg1.Xso2);
  Hsf=ThermoSysPro.Properties.FlueGases.FlueGases_h(Psf, Tsf, Cfg1.Xco2, Cfg1.Xh2o, Cfg1.Xo2, Cfg1.Xso2);
  Cpf=ThermoSysPro.Properties.FlueGases.FlueGases_cp(Pef, Tef, Cfg1.Xco2, Cfg1.Xh2o, Cfg1.Xo2, Cfg1.Xso2);
  rhof=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pef, Tef, Cfg1.Xco2, Cfg1.Xh2o, Cfg1.Xo2, Cfg1.Xso2);
  proee=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pee, Hee, mode);
  Tee=proee.T;
  proem=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Pee + Pse)/2, (Hee + Hse)/2, mode);
  rhoe=proem.d;
  Cpe=noEvent(if proee.x <= 0.0 or proee.x >= 1.0 then proee.cp else 1000000.0);
  proes=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pse, Hse, mode);
  Tse=proes.T;
end StaticExchangerWaterSteamFlueGases;
