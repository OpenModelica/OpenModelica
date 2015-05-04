within ThermoSysPro.FlueGases.Machines;
model CombustionTurbine "Combustion turbine"
  parameter Real A3=0 "X^3 coefficient of the efficiency curve";
  parameter Real A2=-0.04778 "X^2 coefficient of the efficiency curve";
  parameter Real A1=0.09555 "X^1 coefficient of the efficiency curve";
  parameter Real A0=0.95223 "X^0 coefficient of the efficiency curve";
  parameter Real tau_n=0.07 "Nominal expansion rate";
  parameter Real is_eff_n=0.86 "Nominal isentropic efficiency";
  parameter Real Qred=0.01 "Reduced mass flow rate";
  Real tau(start=0.07) "Expansion rate";
  Real is_eff(start=0.85) "Isentropic efficiency";
  Modelica.SIunits.Power Wcp(start=1000000000.0) "Compressor power";
  Modelica.SIunits.Power Wturb(start=2000000000.0) "Turbine power";
  Modelica.SIunits.Power Wmech(start=1000000000.0) "Mechanical power";
  ThermoSysPro.Units.AbsolutePressure Pe(start=100000.0) "Flue gases pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Ps(start=100000.0) "Flue gases pressure at the outlet";
  Real Xtau(start=1) "Ratio between the actual and nominal expansion rate";
  Modelica.SIunits.MassFlowRate Q(start=500) "Flue gases mass flow rate";
  ThermoSysPro.Units.AbsoluteTemperature Te(start=1400.0) "Flue gases temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Ts(start=900) "Flue gases temperature at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tis(start=750) "Isentropic air temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy He(start=1200000.0) "Flue gases specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hs(start=600000.0) "Flue gases specific enthalpy at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy His(start=600000.0) "Flue gases specific enthalpy after the isentropic expansion";
  Modelica.SIunits.SpecificEntropy Se "Flue gases specific entropy at the inlet";
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Ce annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Cs annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal CompressorPower annotation(Placement(transformation(x=-110.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0), iconTransformation(x=-110.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal MechPower annotation(Placement(transformation(x=110.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0), iconTransformation(x=110.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  annotation(Diagram(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,40},{-100,-40},{100,-100},{100,100},{-100,40}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward)}), Icon(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,40},{-100,-40},{100,-100},{100,100},{-100,40}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward)}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"), Diagram(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}})), Icon(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}})));
equation
  Pe=Ce.P;
  Q=Ce.Q;
  Te=Ce.T;
  Ps=Cs.P;
  Q=Cs.Q;
  Ts=Cs.T;
  Wcp=CompressorPower.signal;
  Cs.Xco2=Ce.Xco2;
  Cs.Xh2o=Ce.Xh2o;
  Cs.Xo2=Ce.Xo2;
  Cs.Xso2=Ce.Xso2;
  tau=Ps/Pe;
  Xtau=tau/tau_n;
  is_eff=(A3*Xtau^3 + A2*Xtau^2 + A1*Xtau + A0)*is_eff_n;
  Qred=Q*sqrt(Te)/Pe;
  Wturb=Q*(He - Hs);
  Wmech=Wturb + Wcp;
  MechPower.signal=Wmech;
  He=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pe, Te, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  Se=ThermoSysPro.Properties.FlueGases.FlueGases_s(Pe, Te, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  Se=ThermoSysPro.Properties.FlueGases.FlueGases_s(Ps, Tis, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  His=ThermoSysPro.Properties.FlueGases.FlueGases_h(Ps, Tis, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  Hs=is_eff*(His - He) + He;
  Hs=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pe, Ts, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
end CombustionTurbine;
