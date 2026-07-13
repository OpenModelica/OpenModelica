within ModelicaDataReconciliationSimpleTests.Components.Junctions;
model Mixer4 "Mixer with four inlets"
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5 - 3: Simple";
  parameter Modelica.Units.SI.SpecificHeatCapacity cp=4200 "Specific heat capacity";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real alpha1 "Extraction coefficient for inlet 1 (<=1)";
  Real alpha2 "Extraction coefficient for inlet 2 (<=1)";
  Modelica.Units.SI.Pressure P(start=10e5) "Fluid pressure";
  Modelica.Units.SI.SpecificEnthalpy h(start=10e5) "Fluid specific enthalpy";
  Modelica.Units.SI.Temperature T "Fluid temperature";
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce2 annotation (Placement(transformation(extent={{-50,-110},{-30,-90}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs annotation (Placement(transformation(extent={{90,-10},{110,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce1 annotation (Placement(transformation(extent={{-50,90},{-30,110}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ialpha1 "Extraction coefficient for inlet 1 (<=1)" annotation (Placement(transformation(extent={{-80,70},{-60,90}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation (Placement(transformation(extent={{-20,70},{0,90}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce3 annotation (Placement(transformation(extent={{-110,30},{-90,50}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ialpha2 "Extraction coefficient for inlet 2 (<=1)" annotation (Placement(transformation(extent={{-80,-88},{-60,-68}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Oalpha2 annotation (Placement(transformation(extent={{-20,-90},{0,-70}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce4 annotation (Placement(transformation(extent={{-110,-48},{-90,-28}}, rotation=0)));
equation
  if cardinality(Ialpha1) == 0 then
    Ialpha1.signal = 1;
  end if;
  if cardinality(Ialpha2) == 0 then
    Ialpha2.signal = 1;
  end if;
  /* Fluid pressure */
  P = Ce1.P;
  P = Ce2.P;
  P = Ce3.P;
  P = Ce4.P;
  P = Cs.P;
  /* Fluid specific enthalpy (singular if all flows = 0) */
  Ce1.h_vol = h;
  Ce2.h_vol = h;
  Ce3.h_vol = h;
  Ce4.h_vol = h;
  Cs.h_vol = h;
  /* Mass balance equation */
  0 = Ce1.Q + Ce2.Q + Ce3.Q + Ce4.Q - Cs.Q;
  /* Energy balance equation */
  0 = Ce1.Q*Ce1.h + Ce2.Q*Ce2.h + Ce3.Q*Ce3.h + Ce4.Q*Ce4.h - Cs.Q*Cs.h;
  /* Mass flow at outlet 1 */
  if cardinality(Ialpha1) <> 0 then
    Ce1.Q = Ialpha1.signal*Cs.Q;
  end if;
  if cardinality(Ialpha2) <> 0 then
    Ce2.Q = Ialpha1.signal*Cs.Q;
  end if;
  alpha1 = 1;
  //Ce1.Q / Cs.Q;
  Oalpha1.signal = alpha1;
  alpha2 = 1;
  //Ce2.Q / Cs.Q;
  Oalpha2.signal = alpha2;
  /* Fluid thermodynamic properties */
  if fluid == 3 then
    h = cp*(T - 273.16);
  else
    T = ThermoSysPro.Properties.Fluid.Temperature_Ph(
      P,
      h,
      fluid,
      mode,
      0,
      0,
      0,
      0);
  end if;
  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Polygon(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          points={{-100,60},{-60,60},{-60,100},{-20,100},{-20,60},{-20,20},{100,20},{100,-20},{-20,-20},{-20,-100},{-60,-100},{-60,-60},{-100,-60},{-100,-20},{-60,-20},{-60,20},{-100,20},{-100,60}}),Text(extent={{-60,90},{-20,50}}, textString="1"),Text(extent={{-96,60},{-56,20}}, textString="3"),Text(extent={{-96,-20},{-56,-60}}, textString="4"),Text(extent={{-60,-54},{-20,-94}}, textString="2")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Polygon(
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          points={{-100,60},{-60,60},{-60,100},{-20,100},{-20,60},{-20,20},{100,20},{100,-20},{-20,-20},{-20,-100},{-60,-100},{-60,-60},{-100,-60},{-100,-20},{-60,-20},{-60,20},{-100,20},{-100,60}}),Text(extent={{-96,-20},{-56,-60}}, textString="4"),Text(extent={{-60,-54},{-20,-94}}, textString="2"),Text(extent={{-96,60},{-56,20}}, textString="3"),Text(extent={{-60,90},{-20,50}}, textString="1")}),
    Window(
      x=0.33,
      y=0.09,
      width=0.71,
      height=0.88),
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
end Mixer4;
