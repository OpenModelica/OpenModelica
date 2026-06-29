within ModelicaDataReconciliationSimpleTests.Components.Junctions;
model Splitter22 "Splitter with two outlets"
  parameter Modelica.Units.SI.Power W=0 "Heating power";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5 - 3: simple";
  parameter Modelica.Units.SI.SpecificHeatCapacity cp=4200 "Specific heat capacity";
  parameter Real b=190e-5;
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real alpha1 "Extraction coefficient for outlet 1 (<=1)";
  Modelica.Units.SI.AbsolutePressure P(start=2e5) "Fluid pressure";
  Modelica.Units.SI.SpecificEnthalpy h(start=1e6) "Fluid specific enthalpy";
  Modelica.Units.SI.Temperature T "Fluid temperature";
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce(
    h(start=1e5),
    h_vol(start=1e5),
    Q(start=2)) annotation (Placement(transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs1(
    h(start=1e6),
    h_vol(start=1e5),
    Q(start=1)) annotation (Placement(transformation(extent={{30,90},{50,110}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs2(
    h(start=1e6),
    h_vol(start=1e5),
    Q(start=1)) annotation (Placement(transformation(extent={{30,-110},{50,-90}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ialpha1 "Extraction coefficient for outlet 1 (<=1)" annotation (Placement(transformation(extent={{0,50},{20,70}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation (Placement(transformation(extent={{60,50},{80,70}}, rotation=0)));
equation
  if cardinality(Ialpha1) == 0 then
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
  0 = Ce.Q*Ce.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h + W;

  /* Mass flow at outlet 1 */
  if cardinality(Ialpha1) <> 0 then
    Cs1.Q = Ialpha1.signal*Ce.Q;
  end if;

  alpha1 = 1;
  //Cs1.Q / Ce.Q;
  Oalpha1.signal = alpha1;

  /* Fluid thermodynamic properties */
  if fluid == 3 then
    h = cp*(T - 273.16) + b*P;
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
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{20,20},{20,100},{60,100}}),Text(extent={{20,80},{60,40}}, textString="1"),Text(extent={{20,-40},{60,-80}}, textString="2")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Polygon(
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid,
          points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{20,20},{20,100},{60,100}}),Text(extent={{20,80},{60,40}}, textString="1"),Text(extent={{20,-40},{60,-80}}, textString="2")}),
    Window(
      x=0.33,
      y=0.09,
      width=0.71,
      height=0.88),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2013</b> </p>
<p><b>ThermoSysPro Version 3.1</h4>
<p>This component model is documented in Sect. 14.8 of the <a href=\"https://www.springer.com/us/book/9783030051044\">ThermoSysPro book</a>. </h4>
</html>", revisions="<html>
<p><u><b>Authors</b></u></p>
<ul>
<li>Baligh El Hefni</li>
<li>Daniel Bouskela </li>
</ul>
</html>"),
    DymolaStoredErrors);
end Splitter22;
