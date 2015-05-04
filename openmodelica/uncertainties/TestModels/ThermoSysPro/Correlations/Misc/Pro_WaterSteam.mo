within ThermoSysPro.Correlations.Misc;
record Pro_WaterSteam "Water/steam properties for the computation of correlations"
  ThermoSysPro.Units.AbsoluteTemperature TEE "Water/steam temperature at the inlet of the exchanger";
  ThermoSysPro.Units.AbsoluteTemperature TME "Average water/steam temperature";
  Modelica.SIunits.Density rhoME "Average water/steam density";
  Modelica.SIunits.Density rhoSE "Water/steam density at the outlet of the exchanger";
  ThermoSysPro.Units.AbsolutePressure PME(start=10000000.0) "Average water/steam pressure";
  Modelica.SIunits.SpecificEntropy SME "Average water/steam specific entropy";
  Real xm "Average steam mass fraction";
  Modelica.SIunits.SpecificHeatCapacity cpME "Water/steam specific heat capacity";
  Modelica.SIunits.DynamicViscosity muME "Water/steam dynamic viscosity";
  Modelica.SIunits.ThermalConductivity kME "Water/steam thermal conductivity";
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
end Pro_WaterSteam;
