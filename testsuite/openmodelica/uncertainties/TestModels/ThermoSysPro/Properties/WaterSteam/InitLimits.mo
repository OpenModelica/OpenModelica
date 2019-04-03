within ThermoSysPro.Properties.WaterSteam;
package InitLimits
  constant Real MINPOS=1e-09 "minimal value for physical variables which are always > 0.0";
  constant Modelica.SIunits.Area AMIN=MINPOS "Minimum surface";
  constant Modelica.SIunits.Area AMAX=100000.0 "Maximum surface";
  constant Modelica.SIunits.Area ANOM=1.0 "Nominal surface";
  constant Modelica.SIunits.Density DMIN=MINPOS "Minimum density";
  constant Modelica.SIunits.Density DMAX=100000.0 "Maximum densitye";
  constant Modelica.SIunits.Density DNOM=998.0 "Nominal density";
  constant Modelica.SIunits.ThermalConductivity LAMMIN=MINPOS "Minimum thermal conductivity";
  constant Modelica.SIunits.ThermalConductivity LAMNOM=1.0 "Nominal thermal conductivity";
  constant Modelica.SIunits.ThermalConductivity LAMMAX=1000.0 "Maximum thermal conductivity";
  constant Modelica.SIunits.DynamicViscosity ETAMIN=MINPOS "Minimum dynamic viscosity";
  constant Modelica.SIunits.DynamicViscosity ETAMAX=100000000.0 "Maximum dynamic viscosity";
  constant Modelica.SIunits.DynamicViscosity ETANOM=100.0 "Nominal dynamic viscosity";
  constant Modelica.SIunits.Energy EMIN=-10000000000.0 "Minimum energy";
  constant Modelica.SIunits.Energy EMAX=10000000000.0 "Maximum energy";
  constant Modelica.SIunits.Energy ENOM=1000.0 "Nominal energy";
  constant Modelica.SIunits.Entropy SMIN=-1000000.0 "Minimum entropy";
  constant Modelica.SIunits.Entropy SMAX=1000000.0 "Maximum entropy";
  constant Modelica.SIunits.Entropy SNOM=1000.0 "Nominal entropy";
  constant Modelica.SIunits.MassFlowRate MDOTMIN=-100000.0 "Minimum mass flow rate";
  constant Modelica.SIunits.MassFlowRate MDOTMAX=100000.0 "Maximum mass flow rate";
  constant Modelica.SIunits.MassFlowRate MDOTNOM=1.0 "Nominal mass flow rate";
  constant ThermoSysPro.Units.MassFraction MASSXMIN=-1.0*MINPOS "Minimum mass fraction";
  constant ThermoSysPro.Units.MassFraction MASSXMAX=1.0 "Maximum mass fraction";
  constant ThermoSysPro.Units.MassFraction MASSXNOM=0.1 "Nominal mass fraction";
  constant Modelica.SIunits.Mass MMIN=1.0*MINPOS "Minimum mass";
  constant Modelica.SIunits.Mass MMAX=100000000.0 "Maximum mass";
  constant Modelica.SIunits.Mass MNOM=1.0 "Nominal mass";
  constant Modelica.SIunits.Power POWMIN=-100000000.0 "Minimum power";
  constant Modelica.SIunits.Power POWMAX=100000000.0 "Maximum power";
  constant Modelica.SIunits.Power POWNOM=1000.0 "Nominal power";
  constant ThermoSysPro.Units.AbsolutePressure PMIN=100.0 "Minimum pressure";
  constant ThermoSysPro.Units.AbsolutePressure PMAX=1000000000.0 "Maximum pressure";
  constant ThermoSysPro.Units.AbsolutePressure PNOM=100000.0 "Nominal pressure";
  constant ThermoSysPro.Units.AbsolutePressure COMPPMIN=-1.0*MINPOS "Minimum pressure";
  constant ThermoSysPro.Units.AbsolutePressure COMPPMAX=100000000.0 "Maximum pressure";
  constant ThermoSysPro.Units.AbsolutePressure COMPPNOM=100000.0 "Nominal pressure";
  constant Modelica.SIunits.RatioOfSpecificHeatCapacities KAPPAMIN=1.0 "Minimum isentropic exponent";
  constant Modelica.SIunits.RatioOfSpecificHeatCapacities KAPPAMAX=Modelica.Constants.inf "Maximum isentropic exponent";
  constant Modelica.SIunits.RatioOfSpecificHeatCapacities KAPPANOM=1.2 "Nominal isentropic exponent";
  constant Modelica.SIunits.SpecificEnergy SEMIN=-100000000.0 "Minimum specific energy";
  constant Modelica.SIunits.SpecificEnergy SEMAX=100000000.0 "Maximum specific energy";
  constant Modelica.SIunits.SpecificEnergy SENOM=1000000.0 "Nominal specific energy";
  constant ThermoSysPro.Units.SpecificEnthalpy SHMIN=-1000000.0 "Minimum specific enthalpy";
  constant ThermoSysPro.Units.SpecificEnthalpy SHMAX=100000000.0 "Maximum specific enthalpy";
  constant ThermoSysPro.Units.SpecificEnthalpy SHNOM=1000000.0 "Nominal specific enthalpy";
  constant Modelica.SIunits.SpecificEntropy SSMIN=-1000000.0 "Minimum specific entropy";
  constant Modelica.SIunits.SpecificEntropy SSMAX=1000000.0 "Maximum specific entropy";
  constant Modelica.SIunits.SpecificEntropy SSNOM=1000.0 "Nominal specific entropy";
  constant Modelica.SIunits.SpecificHeatCapacity CPMIN=MINPOS "Minimum specific heat capacity";
  constant Modelica.SIunits.SpecificHeatCapacity CPMAX=Modelica.Constants.inf "Maximum specific heat capacity";
  constant Modelica.SIunits.SpecificHeatCapacity CPNOM=1000.0 "Nominal specific heat capacity";
  constant ThermoSysPro.Units.AbsoluteTemperature TMIN=200 "Minimum temperature";
  constant ThermoSysPro.Units.AbsoluteTemperature TMAX=6000 "Maximum temperature";
  constant ThermoSysPro.Units.AbsoluteTemperature TNOM=320.0 "Nominal temperature";
  constant Modelica.SIunits.ThermalConductivity LMIN=MINPOS "Minimum thermal conductivity";
  constant Modelica.SIunits.ThermalConductivity LMAX=500.0 "Maximum thermal conductivity";
  constant Modelica.SIunits.ThermalConductivity LNOM=1.0 "Nominal thermal conductivity";
  constant Modelica.SIunits.Velocity VELMIN=-100000.0 "Minimum velocity";
  constant Modelica.SIunits.Velocity VELMAX=Modelica.Constants.inf "Maximum velocity";
  constant Modelica.SIunits.Velocity VELNOM=1.0 "Nominal velocity";
  constant Modelica.SIunits.Volume VMIN=0.0 "Minimum volume";
  constant Modelica.SIunits.Volume VMAX=100000.0 "Maximum volume";
  constant Modelica.SIunits.Volume VNOM=0.001 "Nominal volume";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-120,135},{120,70}}, textString="%name", fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-90,40},{70,10}}, textString="Library", fillColor={160,160,160}),Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the ThermoFlow library  (H. Tummescheit)</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
end InitLimits;
