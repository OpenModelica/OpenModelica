﻿within DataReconciliationSimpleTests.QPLib.Junctions;
model Splitter2 "Splitter with two outlets"
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Integer mode=0
    "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";

public
  Real alpha1 "Extraction coefficient for outlet 1 (<=1)";
  Modelica.SIunits.AbsolutePressure P(start=10e5) "Fluid pressure";
  Modelica.SIunits.SpecificEnthalpy h(start=10e5) "Fluid specific enthalpy";
  Modelica.SIunits.Temperature T "Fluid temperature";

public
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce annotation (Placement(
        transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs1 annotation (Placement(
        transformation(extent={{30,90},{50,110}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs2 annotation (Placement(
        transformation(extent={{30,-110},{50,-90}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ialpha1
    "Extraction coefficient for outlet 1 (<=1)"
    annotation (Placement(transformation(extent={{0,50},{20,70}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Oalpha1
    annotation (Placement(transformation(extent={{60,50},{80,70}}, rotation=0)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
    "Propriétés de l'eau"
    annotation (Placement(transformation(extent={{-100,80},{-80,100}}, rotation=
           0)));
equation

  if (cardinality(Ialpha1) == 0) then
    Ialpha1.signal = 0.5;
  end if;

  /* Fluid pressure */
  P = Ce.P;
  P = Cs1.P;
  P = Cs2.P;

  /* Fluid specific enthalpy (singular if all flows = 0) */
  Ce.h_vol = h;
  Cs1.h_vol = h;
  Cs2.h_vol = h;

  /* Mass balance equation */
  0 = Ce.Q - Cs1.Q - Cs2.Q;

  /* Energy balance equation */
  0 = Ce.Q*Ce.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h;

  /* Mass flow at outlet 1 */
  if (cardinality(Ialpha1) <> 0) then
    Cs1.Q = Ialpha1.signal*Ce.Q;
  end if;

  alpha1 = Cs1.Q/Ce.Q;
  Oalpha1.signal = alpha1;

  /* Fluid thermodynamic properties */
  pro = ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);

  T = pro.T;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Polygon(
          points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{
              20,20},{20,100},{60,100}},
          lineColor={0,0,0},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{20,80},{60,40}}, textString=
                                     "1"),
        Text(extent={{20,-40},{60,-80}}, textString=
                             "2")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Polygon(
          points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{
              20,20},{20,100},{60,100}},
          lineColor={0,0,0},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{20,80},{60,40}}, textString=
                                     "1"),
        Text(extent={{20,-40},{60,-80}}, textString=
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
"), DymolaStoredErrors);
end Splitter2;
