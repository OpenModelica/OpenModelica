within DataReconciliationSimpleTests.QPLib.Connectors;
connector FluidInlet "Water/steam inlet fluid connector"
  Modelica.SIunits.AbsolutePressure P(start=1.e5)
    "Fluid pressure in the control volume";
  Modelica.SIunits.MassFlowRate Q(start=500)
    "Mass flow rate of the fluid crossing the boundary of the control volume";
  annotation (
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,255},
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid)}),
    Window(
      x=0.27,
      y=0.33,
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
end FluidInlet;
