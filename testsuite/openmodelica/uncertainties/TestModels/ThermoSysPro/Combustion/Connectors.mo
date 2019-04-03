within ThermoSysPro.Combustion;
package Connectors "Connectors"
  connector FuelInlet "Fuel inlet connector"
    Modelica.SIunits.MassFlowRate Q "Fuel mass flow rate";
    ThermoSysPro.Units.AbsoluteTemperature T "Fuel temperature";
    ThermoSysPro.Units.AbsolutePressure P "Fuel pressure";
    Modelica.SIunits.SpecificEnergy LHV "Lower heating value";
    Modelica.SIunits.SpecificHeatCapacity cp "Fuel specific heat capacity at 273.15 K";
    Real hum "Fuel humidity (%)";
    Real Xc "C mass fraction";
    Real Xh "H mass fraction";
    Real Xo "O mass fraction";
    Real Xn "N mass fraction";
    Real Xs "S mass fraction";
    Real Xashes "Ashes mass fraction";
    Real VolM "Percentage of volatile matter";
    Modelica.SIunits.Density rho "Fuel density";
    input Boolean a=true "Pseudo-variable for the verification of the connection orientation";
    output Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,0}, fillPattern=FillPattern.VerticalCylinder, fillColor={0,0,0}),Ellipse(extent={{-100,100},{100,-100}}, lineColor={0,0,0}, fillPattern=FillPattern.Sphere, fillColor={0,127,255})}), Documentation(revisions="", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  end FuelInlet;

  connector FuelOutlet "Fuel outlet connector"
    Modelica.SIunits.MassFlowRate Q "Fuel mass flow rate";
    ThermoSysPro.Units.AbsoluteTemperature T "Fuel temperature";
    ThermoSysPro.Units.AbsolutePressure P "Fuel pressure";
    Modelica.SIunits.SpecificEnergy LHV "Lower heating value";
    Modelica.SIunits.SpecificHeatCapacity cp "Fuel specific heat capacity at 273.15 K";
    Real hum "Fuel humidity (%)";
    Real Xc "C mass fraction";
    Real Xh "H mass fraction";
    Real Xo "O mass fraction";
    Real Xn "N mass fraction";
    Real Xs "S mass fraction";
    Real Xashes "Ashes mass fraction";
    Real VolM "Percentage of volatile matter";
    Modelica.SIunits.Density rho "Fuel density";
    output Boolean a "Pseudo-variable for the verification of the connection orientation";
    input Boolean b=true "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Forward),Ellipse(extent={{-100,100},{100,-100}}, lineColor={0,0,0}, fillPattern=FillPattern.Sphere, fillColor={255,0,0})}), Documentation(revisions="", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  end FuelOutlet;

  connector FuelInletI "Internal fuel inlet connector"
    Modelica.SIunits.MassFlowRate Q "Fuel mass flow rate";
    ThermoSysPro.Units.AbsoluteTemperature T "Fuel temperature";
    ThermoSysPro.Units.AbsolutePressure P "Fuel pressure";
    Modelica.SIunits.SpecificEnergy LHV "Lower heating value";
    Modelica.SIunits.SpecificHeatCapacity cp "Fuel specific heat capacity at 273.15 K";
    Real hum "Fuel humidity (%)";
    Real Xc "C mass fraction";
    Real Xh "H mass fraction";
    Real Xo "O mass fraction";
    Real Xn "N mass fraction";
    Real Xs "S mass fraction";
    Real Xashes "Ashes mass fraction";
    Real VolM "Percentage of volatile matter";
    Modelica.SIunits.Density rho "Fuel density";
    input Boolean a "Pseudo-variable for the verification of the connection orientation";
    output Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,0}, fillPattern=FillPattern.VerticalCylinder, fillColor={0,0,0}),Ellipse(extent={{-100,100},{100,-100}}, lineColor={0,0,255}, fillColor={0,127,255}, fillPattern=FillPattern.Backward)}), Documentation(revisions="", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  end FuelInletI;

  connector FuelOutletI "Internal fuel outlet connector"
    Modelica.SIunits.MassFlowRate Q "Fuel mass flow rate";
    ThermoSysPro.Units.AbsoluteTemperature T "Fuel temperature";
    ThermoSysPro.Units.AbsolutePressure P "Fuel pressure";
    Modelica.SIunits.SpecificEnergy LHV "Lower heating value";
    Modelica.SIunits.SpecificHeatCapacity cp "Fuel specific heat capacity at 273.15 K";
    Real hum "Fuel humidity (%)";
    Real Xc "C mass fraction";
    Real Xh "H mass fraction";
    Real Xo "O mass fraction";
    Real Xn "N mass fraction";
    Real Xs "S mass fraction";
    Real Xashes "Ashes mass fraction";
    Real VolM "Percentage of volatile matter";
    Modelica.SIunits.Density rho "Fuel density";
    output Boolean a "Pseudo-variable for the verification of the connection orientation";
    input Boolean b "Pseudo-variable for the verification of the connection orientation";
    annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,0}, fillPattern=FillPattern.VerticalCylinder, fillColor={0,0,0}),Ellipse(extent={{-100,100},{100,-100}}, lineColor={0,0,255}, fillColor={255,0,0}, fillPattern=FillPattern.Backward)}), Documentation(revisions="", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  end FuelOutletI;

end Connectors;
