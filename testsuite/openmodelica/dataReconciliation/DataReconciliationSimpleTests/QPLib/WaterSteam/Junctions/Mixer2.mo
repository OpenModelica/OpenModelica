within DataReconciliationSimpleTests.QPLib.WaterSteam.Junctions;
model Mixer2 "Mixer with two inlets"

public
  Real alpha1 "Extraction coefficient for inlet 1 (<=1)";
  Modelica.SIunits.AbsolutePressure P(start=10e5) "Fluid pressure";

public
  Connectors.FluidInlet Ce2 annotation (Placement(transformation(extent={{-50,-110},
            {-30,-90}}, rotation=0)));
  Connectors.FluidOutlet Cs annotation (Placement(transformation(extent={{90,-10},
            {110,10}}, rotation=0)));
public
  Connectors.FluidInlet Ce1 annotation (Placement(transformation(extent={{-50,90},
            {-30,110}}, rotation=0)));
  InstrumentationAndControl.Connectors.InputReal Ialpha1
    "Extraction coefficient for inlet 1 (<=1)" annotation (Placement(
        transformation(extent={{-80,50},{-60,70}}, rotation=0)));
  InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation (Placement(
        transformation(extent={{-20,50},{0,70}}, rotation=0)));
equation

  if (cardinality(Ialpha1) == 0) then
    Ialpha1.signal = 0.5;
  end if;

  /* Fluid pressure */
  P = Ce1.P;
  P = Ce2.P;
  P = Cs.P;

  /* Mass balance equation */
  0 = Ce1.Q + Ce2.Q - Cs.Q;

  /* Mass flow at outlet 1 */
  if (cardinality(Ialpha1) <> 0) then
    Ce1.Q = Ialpha1.signal*Cs.Q;
  end if;

  alpha1 = Ce1.Q/Cs.Q;
  Oalpha1.signal = alpha1;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Polygon(
          points={{-60,-100},{-20,-100},{-20,-20},{100,-20},{100,20},{-20,20},{
              -20,100},{-60,100},{-60,-100}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{-60,80},{-20,40}}, textString=
                                     "1"),
        Text(extent={{-60,-40},{-20,-80}}, textString=
                             "2")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Polygon(
          points={{-60,-100},{-20,-100},{-20,-20},{100,-20},{100,20},{-20,20},{
              -20,100},{-60,100},{-60,-100}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{-60,80},{-20,40}}, textString=
                                     "1"),
        Text(extent={{-60,-40},{-20,-80}}, textString=
                             "2")}),
    Window(
      x=0.33,
      y=0.09,
      width=0.71,
      height=0.88),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2013</b> </p>
<p><b>ThermoSysPro Version 3.1</b> </p>
</html>",
   revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
end Mixer2;
