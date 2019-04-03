within ThermoSysPro.Thermal;
package Connectors "Connectors"
  connector ThermalPort "Thermal connector"
    ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
    flow Modelica.SIunits.HeatFlowRate W "Thermal flow rate. Positive when going into the component";
    annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,100},{100,-100}}, lineColor={0,0,0}, fillPattern=FillPattern.Sphere, fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  end ThermalPort;

end Connectors;
