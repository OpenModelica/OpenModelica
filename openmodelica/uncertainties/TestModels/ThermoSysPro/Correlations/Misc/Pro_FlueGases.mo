within ThermoSysPro.Correlations.Misc;
record Pro_FlueGases "Flue gases properties for the computation of correlations"
  Modelica.SIunits.Density rhoMF(start=0.5) "Flue gases average density";
  Modelica.SIunits.SpecificHeatCapacity cpMF(start=500) "Flue gases average specific heat capacity";
  Modelica.SIunits.DynamicViscosity muMF(start=1e-05) "Flue gases average dynamic viscosity";
  Modelica.SIunits.ThermalConductivity kMF(start=0.1) "Flue gases average thermal conductivity";
  Modelica.SIunits.SpecificHeatCapacity cpMFF(start=500) "Film specific heat capacity";
  Modelica.SIunits.DynamicViscosity muMFF(start=1e-05) "Film dynamic viscosity";
  Modelica.SIunits.ThermalConductivity kMFF(start=0.1) "Film thermal conductivity";
  Real Xtot " ";
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
end Pro_FlueGases;
