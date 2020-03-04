within DataReconciliationSimpleTests.QPLib.InstrumentationAndControl.Connectors;
connector OutputReal
    output Real signal;
    annotation (
      Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Polygon(
          points={{-100,100},{-100,-100},{100,0},{-100,100}},
          lineColor={0,0,255},
          fillColor={0,255,255},
          fillPattern=FillPattern.Solid)}),
      Window(
        x=0.34,
        y=0.18,
        width=0.6,
        height=0.6),
      Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
end OutputReal;
