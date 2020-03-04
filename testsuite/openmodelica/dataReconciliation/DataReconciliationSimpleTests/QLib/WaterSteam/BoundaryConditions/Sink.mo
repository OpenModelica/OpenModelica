within DataReconciliationSimpleTests.QLib.WaterSteam.BoundaryConditions;
model Sink "Water/steam sink"

public
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";

  Connectors.FluidInlet C annotation (Placement(transformation(extent={{-110,-10},
            {-90,10}}, rotation=0)));
equation

  C.Q = Q;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{-90,0},{-40,0},{-54,10}}),
        Line(points={{-54,-10},{-40,0}}),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid)}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Line(points={{-92,0},{-40,0},{-54,10}}),
        Line(points={{-54,-10},{-40,0}})}),
    Window(
      x=0.23,
      y=0.15,
      width=0.81,
      height=0.71),
    Documentation(info="<html>
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
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
end Sink;
