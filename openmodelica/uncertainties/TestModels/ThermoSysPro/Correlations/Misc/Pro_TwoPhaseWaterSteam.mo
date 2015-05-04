within ThermoSysPro.Correlations.Misc;
record Pro_TwoPhaseWaterSteam "Water/steam properties for the computation of correlations"
  Modelica.SIunits.Density rhol "Density of the liquid phase";
  Modelica.SIunits.Density rhov "Density of the vapor phase";
  ThermoSysPro.Units.SpecificEnthalpy hl "Specific enthalpy of the liquid phase";
  ThermoSysPro.Units.SpecificEnthalpy hv "Specific enthalpy of the vapor phase";
  Modelica.SIunits.SpecificEnergy lv "Phase transition energy";
  Modelica.SIunits.SpecificHeatCapacity cpl "Specific heat capacity of the liquid phase";
  Modelica.SIunits.SpecificHeatCapacity cpv "Specific heat capacity of the vapor phase";
  Modelica.SIunits.DynamicViscosity mul "Dynamic viscosity of the liquid phase";
  Modelica.SIunits.DynamicViscosity muv "Dynamic viscosity of the vapor phase";
  Modelica.SIunits.ThermalConductivity kl "Thermal conductivity of the liquid phase";
  Modelica.SIunits.ThermalConductivity kv "Thermal conductivity of the vapor phase";
  Modelica.SIunits.SurfaceTension tsl "Surface tension of the liquid phase";
  Modelica.SIunits.Density rholv "Density of the water/steam mixture";
  ThermoSysPro.Units.SpecificEnthalpy hlv "Specific enthalpy of the water/steam mixture";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,50},{100,-100}}, fillColor={255,255,127}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-127,115},{127,55}}, textString="%name"),Line(points={{-100,-50},{100,-50}}, color={0,0,0}),Line(points={{-100,0},{100,0}}, color={0,0,0}),Line(points={{0,50},{0,-100}}, color={0,0,0})}), Documentation(revisions="<html>
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
"));
end Pro_TwoPhaseWaterSteam;
