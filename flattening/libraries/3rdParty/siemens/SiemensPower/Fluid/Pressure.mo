within SiemensPower.Fluid;
model Pressure "Ideal pressure sensor"
  extends SiemensPower.Fluid.PartialAbsoluteSensor;
  extends Modelica.Icons.RotationalSensor;
  Modelica.Blocks.Interfaces.RealOutput p(final quantity="Pressure",
                                          final unit="Pa",
                                          displayUnit="bar",
                                          min=0) "Pressure at port"
    annotation (Placement(transformation(extent={{100,-10},{120,10}},
          rotation=0)));
equation
  p = port.p;
  annotation (
  Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics),
  Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Line(points={{70,0},{100,0}}, color={0,0,127}),
        Line(points={{0,-70},{0,-100}}, color={0,127,255}),
        Text(
          extent={{-150,80},{150,120}},
          textString="%name",
          lineColor={0,0,255}),
        Text(
          extent={{151,-20},{57,-50}},
          lineColor={0,0,0},
          textString="p")}),
    Documentation(info="<HTML>
<p>
This component monitors the absolute pressure at its fluid port. The sensor is
ideal, i.e., it does not influence the fluid.
</p>
</HTML>
"));
end Pressure;
