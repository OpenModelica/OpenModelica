within DataReconciliationSimpleTests.QLib.WaterSteam.Connectors;
connector FluidOutlet "Water/steam outlet fluid connector"
  Modelica.SIunits.MassFlowRate Q(start=500)
    "Mass flow rate of the fluid crossing the boundary of the control volume";

  annotation (
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,255},
          fillColor={255,0,0},
          fillPattern=FillPattern.Solid)}),
    Window(
      x=0.26,
      y=0.39,
      width=0.6,
      height=0.6),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
",
 revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
end FluidOutlet;
