within DataReconciliationSimpleTests.QPLib.WaterSteam.BoundaryConditions;
model SinkP "Water/steam sink with fixed pressure"
  parameter Modelica.SIunits.AbsolutePressure P0=100000 "Sink pressure";

public
  Modelica.SIunits.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";

public
  InstrumentationAndControl.Connectors.InputReal              IPressure
    annotation (Placement(transformation(
        origin={50,0},
        extent={{-10,-10},{10,10}},
        rotation=180)));
  Connectors.FluidInlet C annotation (Placement(transformation(extent={{-110,-10},
            {-90,10}}, rotation=0)));
equation

  C.P = P;
  C.Q = Q;

  if (cardinality(IPressure) == 0) then
    IPressure.signal = P0;
  end if;

  P = IPressure.signal;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{-90,0},{-40,0},{-58,10}}),
        Line(points={{-40,0},{-58,-10}}),
        Text(extent={{40,28},{58,8}}, textString=
                                          "P"),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={127,255,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{-94,26},{98,-30}}, textString=
                                             "P")}),
    Window(
      x=0.06,
      y=0.16,
      width=0.67,
      height=0.71),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{-90,0},{-40,0},{-58,10}}),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={127,255,0},
          fillPattern=FillPattern.Solid),
        Line(points={{-40,0},{-58,-10}}),
        Text(extent={{-94,26},{98,-30}}, textString=
                                             "P"),
        Text(extent={{40,28},{58,8}}, textString=
                                          "P"),
        Text(extent={{-40,-40},{-10,-60}}, textString=
                                             "h / T")}),
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
    Daniel Bouskela</li>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
end SinkP;
