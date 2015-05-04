within SiemensPower.Fluid;
partial class RotationalSensor "Icon representing a round measurement device"

  annotation (
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Ellipse(
          extent={{-70,70},{70,-70}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Line(points={{0,70},{0,40}}, color={0,0,0}),
        Line(points={{22.9,32.8},{40.2,57.3}}, color={0,0,0}),
        Line(points={{-22.9,32.8},{-40.2,57.3}}, color={0,0,0}),
        Line(points={{37.6,13.7},{65.8,23.9}}, color={0,0,0}),
        Line(points={{-37.6,13.7},{-65.8,23.9}}, color={0,0,0}),
        Line(points={{0,0},{9.02,28.6}}, color={0,0,0}),
        Polygon(
          points={{-0.48,31.6},{18,26},{18,57.2},{-0.48,31.6}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{-5,5},{5,-5}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid)}),
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics),
    Documentation(info="<html>
<p>
This icon is designed for a <b>rotational sensor</b> model.
</p>
</html>"));
end RotationalSensor;
