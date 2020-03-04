within DataReconciliationSimpleTests.QPLib.WaterSteam.BoundaryConditions;
model SourceP "Water/steam source with fixed pressure"
  parameter Modelica.SIunits.AbsolutePressure P0=300000 "Source pressure";

public
  Modelica.SIunits.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";

  InstrumentationAndControl.Connectors.InputReal              IPressure
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}}, rotation=
            0)));
  WaterSteam.Connectors.FluidOutlet C annotation (Placement(transformation(
          extent={{90,-10},{110,10}}, rotation=0)));
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
        Line(points={{40,0},{90,0},{72,10}}),
        Line(points={{90,0},{72,-10}}),
        Text(extent={{-58,30},{-40,10}}, textString=
                                             "P"),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={127,255,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{-94,28},{98,-28}}, textString=
                                           "P")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Line(points={{40,0},{90,0},{72,10}}),
        Rectangle(
          extent={{-40,40},{40,-40}},
          lineColor={0,0,255},
          fillColor={127,255,0},
          fillPattern=FillPattern.Solid),
        Line(points={{90,0},{72,-10}}),
        Text(extent={{-94,28},{98,-28}}, textString=
                                           "P"),
        Text(extent={{-58,30},{-40,10}}, textString=
                                             "P"),
        Text(extent={{-40,-40},{-10,-60}}, textString=
                                             "h / T")}),
    Window(
      x=0.45,
      y=0.01,
      width=0.35,
      height=0.49),
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
end SourceP;
