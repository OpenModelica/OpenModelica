within ThermoSysPro.WaterSteam;
package Connectors "Connectors"
  connector FluidInlet "Water/steam inlet fluid connector"
    ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Fluid pressure in the control volume";
    ThermoSysPro.Units.SpecificEnthalpy h_vol(start=100000.0) "Fluid specific enthalpy in the control volume";
    Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate of the fluid crossing the boundary of the control volume";
    ThermoSysPro.Units.SpecificEnthalpy h(start=100000.0) "Specific enthalpy of the fluid crossing the boundary of the control volume";
    input Boolean a=true "Pseudo-variable for the verification of the connection orientation";
    output Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={0,0,255})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
  end FluidInlet;

  connector FluidInletI "Internal water/steam inlet fluid connector"
    ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Fluid pressure in the control volume";
    ThermoSysPro.Units.SpecificEnthalpy h_vol(start=100000.0) "Fluid specific enthalpy in the control volume";
    Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate of the fluid crossing the boundary of the control volume";
    ThermoSysPro.Units.SpecificEnthalpy h(start=100000.0) "Specific enthalpy of the fluid crossing the boundary of the control volume";
    input Boolean a "Pseudo-variable for the verification of the connection orientation";
    output Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillColor={255,255,255}, fillPattern=FillPattern.CrossDiag)}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
  end FluidInletI;

  connector FluidOutlet "Water/steam outlet fluid connector"
    ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Fluid pressure in the control volume";
    ThermoSysPro.Units.SpecificEnthalpy h_vol(start=100000.0) "Fluid specific enthalpy in the control volume";
    Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate of the fluid crossing the boundary of the control volume";
    ThermoSysPro.Units.SpecificEnthalpy h(start=100000.0) "Specific enthalpy of the fluid crossing the boundary of the control volume";
    output Boolean a "Pseudo-variable for the verification of the connection orientation";
    input Boolean b=true "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,0,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
  end FluidOutlet;

  connector FluidOutletI "Internal water/steam outlet fluid connector"
    ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Fluid pressure in the control volume";
    ThermoSysPro.Units.SpecificEnthalpy h_vol(start=100000.0) "Fluid specific enthalpy in the control volume";
    Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate of the fluid crossing the boundary of the control volume";
    ThermoSysPro.Units.SpecificEnthalpy h(start=100000.0) "Specific enthalpy of the fluid crossing the boundary of the control volume";
    output Boolean a "Pseudo-variable for the verification of the connection orientation";
    input Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,100},{100,-100}}, lineColor={255,0,0}, fillColor={255,255,255}, fillPattern=FillPattern.CrossDiag)}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
  end FluidOutletI;

end Connectors;
