within ThermoSysPro.FlueGases;
package Connectors "Connectors"
  connector FlueGasesOutlet "Flue gases outlet fluid connector"
    ThermoSysPro.Units.AbsolutePressure P "Fluid pressure in the control volume";
    ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature in the control volume";
    Modelica.SIunits.MassFlowRate Q "Mass flow of the fluid crossing the boundary of the control volume";
    Real Xco2 "CO2 mass fraction of the fluid crossing the boundary of the control volume";
    Real Xh2o "H2O mass fraction of the fluid crossing the boundary of the control volume";
    Real Xo2 "O2 mass fraction of the fluid crossing the boundary of the control volume";
    Real Xso2 "SO2 mass fraction of the fluid crossing the boundary of the control volume";
    output Boolean a "Pseudo-variable for the verification of the connection orientation";
    input Boolean b=true "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{102,100}}, lineColor={0,0,0}, fillPattern=FillPattern.Sphere, fillColor={191,0,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
  end FlueGasesOutlet;

  connector FlueGasesInlet "Flue gases inlet fluid connector"
    ThermoSysPro.Units.AbsolutePressure P "Fluid pressure in the control volume";
    ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature in the control volume";
    Modelica.SIunits.MassFlowRate Q "Mass flow of the fluid crossing the boundary of the control volume";
    Real Xco2 "CO2 mass fraction of the fluid crossing the boundary of the control volume";
    Real Xh2o "H2O mass fraction of the fluid crossing the boundary of the control volume";
    Real Xo2 "O2 mass fraction of the fluid crossing the boundary of the control volume";
    Real Xso2 "SO2 mass fraction of the fluid crossing the boundary of the control volume";
    input Boolean a=true "Pseudo-variable for the verification of the connection orientation";
    output Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,0}, fillPattern=FillPattern.Sphere, fillColor={127,127,255})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
  end FlueGasesInlet;

  connector FlueGasesInletI "Internal flue gases inlet fluid connector"
    ThermoSysPro.Units.AbsolutePressure P "Fluid pressure in the control volume";
    ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature in the control volume";
    Modelica.SIunits.MassFlowRate Q "Mass flow of the fluid crossing the boundary of the control volume";
    Real Xco2 "CO2 mass fraction of the fluid crossing the boundary of the control volume";
    Real Xh2o "H2O mass fraction of the fluid crossing the boundary of the control volume";
    Real Xo2 "O2 mass fraction of the fluid crossing the boundary of the control volume";
    Real Xso2 "SO2 mass fraction of the fluid crossing the boundary of the control volume";
    input Boolean a "Pseudo-variable for the verification of the connection orientation";
    output Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,0}, lineThickness=1.0, fillColor={127,127,255}, fillPattern=FillPattern.Forward)}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
  end FlueGasesInletI;

  connector FlueGasesOutletI "Internal flue gases outlet fluid connector"
    ThermoSysPro.Units.AbsolutePressure P "Fluid pressure in the control volume";
    ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature in the control volume";
    Modelica.SIunits.MassFlowRate Q "Mass flow of the fluid crossing the boundary of the control volume";
    Real Xco2 "CO2 mass fraction of the fluid crossing the boundary of the control volume";
    Real Xh2o "H2O mass fraction of the fluid crossing the boundary of the control volume";
    Real Xo2 "O2 mass fraction of the fluid crossing the boundary of the control volume";
    Real Xso2 "SO2 mass fraction of the fluid crossing the boundary of the control volume";
    output Boolean a "Pseudo-variable for the verification of the connection orientation";
    input Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,0}, lineThickness=1.0, fillColor={255,0,0}, fillPattern=FillPattern.Forward)}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
  end FlueGasesOutletI;

end Connectors;
