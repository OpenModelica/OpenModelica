within DataReconciliationSimpleTests.QLib.WaterSteam.BoundaryConditions;
model SinkQ "Water/steam sink with fixed mass flow rate"
  parameter Modelica.SIunits.MassFlowRate Q0=100
    "Mass flow (active if IMassFlow connector is not connected)";

public
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";

public
  InstrumentationAndControl.Connectors.InputReal              IMassFlow
    annotation (Placement(transformation(
        origin={0,50},
        extent={{-10,-10},{10,10}},
        rotation=270)));
  Connectors.FluidInlet C annotation (Placement(transformation(extent={{-110,-10},
            {-90,10}}, rotation=0)));
equation

  C.Q = Q;

  /* Mass flow */
  if (cardinality(IMassFlow) == 0) then
    IMassFlow.signal = Q0;
  end if;

  Q = IMassFlow.signal;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{-90,0},{-40,0},{-54,10}}),
        Line(points={{-54,-10},{-40,0}}),
        Text(extent={{12,60},{32,40}}, textString=
                                           "Q"),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-20,20},{22,-24}},
          lineColor={0,0,255},
          textString=
               "Q")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{12,60},{32,40}}, textString=
                                           "Q"),
        Line(points={{-90,0},{-40,0},{-54,10}}),
        Line(points={{-54,-10},{-40,0}}),
        Text(
          extent={{-20,22},{22,-24}},
          lineColor={0,0,255},
          textString=
               "Q")}),
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
end SinkQ;
