within ThermoSysPro.ElectroMechanics;
package Connectors "Connectors"
  connector MechanichalTorque "Mechanical torque"
    Modelica.SIunits.Torque Ctr "Torque";
    Modelica.SIunits.AngularVelocity w "Angular velocity";
    annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,60},{0,60},{100,0},{0,-60},{-100,-60},{-100,60}}, fillPattern=FillPattern.Solid, fillColor={255,255,0})}), Documentation(info="<html>
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
  end MechanichalTorque;

end Connectors;
