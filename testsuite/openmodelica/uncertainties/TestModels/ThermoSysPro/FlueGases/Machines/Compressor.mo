within ThermoSysPro.FlueGases.Machines;
model Compressor "Gas compressor"
  parameter Integer mass_flow_rate_comp=1 "Ways for computing the mass flow rate - 1: Q = rho*Qv - 2: Q = rho*f(T)";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tmax=284.16 "Air transition temperature between f1 = a*x + b and f2 = c*x + d for the computation of Q (active if mass_flow_rate_comp == 2)";
  parameter Real coef1_1=0.1164 "Coefficient a for f1 = a*x + b";
  parameter Real coef2_1=38.643 "Coefficient b for f1 = a*x + b";
  parameter Real coef1_2=-0.2324 "Coefficient c for f2 = c*x + d";
  parameter Real coef2_2=137.49 "Coefficient d for f2 = c*x + d";
  parameter Real A4=-1.2362 "Coefficient of X^4 for the computation of the isentropic efficiency";
  parameter Real A3=3.6721 "Coefficient of X^3 for the computation of the isentropic efficiency";
  parameter Real A2=-4.2434 "Coefficient of X^2 for the computation of the isentropic efficiency";
  parameter Real A1=2.3957 "Coefficient of X^1 for the computation of the isentropic efficiency";
  parameter Real A0=0.4118 "Coefficient of X^0 for the computation of the isentropic efficiency";
  parameter Real tau_n=14.149 "Nominal compression rate";
  parameter Real is_eff_n=0.84752 "Nominal isentropic efficiency";
  Real tau(start=15) "Compression rate";
  Real is_eff(start=0.85) "Isentropic efficiency";
  Modelica.SIunits.Power Wcp(start=1000000000.0) "Compressor power";
  ThermoSysPro.Units.AbsolutePressure Pe(start=100000.0) "Air pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Ps(start=1500000.0) "Air pressure at the outlet";
  Real Xtau(start=1) "Normal and nominal compression rates ratio";
  Modelica.SIunits.MassFlowRate Q(start=500) "Air mass flow rate";
  Modelica.SIunits.VolumeFlowRate Qv(start=500) "Air volume flow rate";
  ThermoSysPro.Units.AbsoluteTemperature Te(start=300) "Air temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Ts(start=750) "Air temperature at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tis(start=750) "Isentropic air temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy He(start=80000.0) "Air specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hs(start=500000.0) "Air specific enthalpy at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy His(start=450000.0) "Air specific enthalpy after the isentropic compression";
  Modelica.SIunits.SpecificEntropy Se "Air specific entropy at the inlet";
  Modelica.SIunits.Density rho_e(start=1) "Air density at the inlet";
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Ce annotation(Placement(transformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Cs annotation(Placement(transformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Power annotation(Placement(transformation(x=90.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0), iconTransformation(x=90.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  annotation(Diagram(coordinateSystem(extent={{-120,-100},{120,100}}), graphics={Polygon(points={{-80,80},{-80,-80},{80,-40},{80,40},{-80,80}}, lineColor={0,0,0}, fillColor={0,255,0}, fillPattern=FillPattern.Backward)}), Icon(coordinateSystem(extent={{-120,-100},{120,100}}), graphics={Polygon(points={{-80,80},{-80,-80},{80,-40},{80,40},{-80,80}}, lineColor={0,0,0}, fillColor={0,255,0}, fillPattern=FillPattern.Backward)}), Documentation(revisions="<html>
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
"), Diagram(coordinateSystem(extent={{-120,-100},{120,100}})), Icon(coordinateSystem(extent={{-120,-100},{120,100}})));
protected
  Modelica.SIunits.VolumeFlowRate Qv_cal(start=500) "Intermediate variable for the computation of Qv";
equation
  Pe=Ce.P;
  Q=Ce.Q;
  Te=Ce.T;
  Ps=Cs.P;
  Q=Cs.Q;
  Ts=Cs.T;
  Cs.Xco2=Ce.Xco2;
  Cs.Xh2o=Ce.Xh2o;
  Cs.Xo2=Ce.Xo2;
  Cs.Xso2=Ce.Xso2;
  tau=Ps/Pe;
  Xtau=tau/tau_n;
  is_eff=(A4*Xtau^4 + A3*Xtau^3 + A2*Xtau^2 + A1*Xtau + A0)*is_eff_n;
  Wcp=Q*(He - Hs);
  Power.signal=Wcp;
  Qv_cal=if Te < Tmax then coef1_1*Te + coef2_1 else coef1_2*Te + coef2_2;
  Q=if mass_flow_rate_comp == 1 then Qv*rho_e else Qv_cal*rho_e;
  He=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pe, Te, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  Se=ThermoSysPro.Properties.FlueGases.FlueGases_s(Pe, Te, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  Se=ThermoSysPro.Properties.FlueGases.FlueGases_s(Ps, Tis, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  His=ThermoSysPro.Properties.FlueGases.FlueGases_h(Ps, Tis, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  rho_e=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pe, Te, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  Hs=(His - He + is_eff*He)/is_eff;
  Hs=ThermoSysPro.Properties.FlueGases.FlueGases_h(Ps, Ts, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
end Compressor;
