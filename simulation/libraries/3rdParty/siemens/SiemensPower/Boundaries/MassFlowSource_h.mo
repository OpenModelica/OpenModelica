within SiemensPower.Boundaries;
model MassFlowSource_h
  "Ideal flow source that produces a prescribed mass flow with prescribed specific enthalpy"
  // needed for parallel flow test, imported from Modelica.Fluid.Sources
  // removed Media

//  extends Sources.BaseClasses.PartialSource;
  parameter Boolean use_m_flow_in = false
    "Get the mass flow rate from the input connector"
    annotation(Evaluate=true, HideResult=true, choices(__Dymola_checkBox=true));
  parameter Boolean use_h_in= false
    "Get the specific enthalpy from the input connector"
    annotation(Evaluate=true, HideResult=true, choices(__Dymola_checkBox=true));
  parameter SiemensPower.Units.MassFlowRate m_flow_start = 0
    "Fixed mass flow rate going out of the fluid port"
    annotation (Evaluate = true,
                Dialog(enable = not use_m_flow_in));
  parameter SiemensPower.Units.SpecificEnthalpy h_start=4e5
    "Fixed value of specific enthalpy"
    annotation (Evaluate = true,
                Dialog(enable = not use_h_in));

  Modelica.Blocks.Interfaces.RealInput m_flow_in if     use_m_flow_in
    "Prescribed mass flow rate"
    annotation (Placement(transformation(extent={{-120,60},{-80,100}},
          rotation=0)));
  Modelica.Blocks.Interfaces.RealInput hIn if              use_h_in
    "Prescribed fluid specific enthalpy"
    annotation (Placement(transformation(extent={{-140,20},{-100,60}},
          rotation=0), iconTransformation(extent={{-140,20},{-100,60}})));

 SiemensPower.Units.AbsolutePressure p;
 SiemensPower.Units.SpecificEnthalpy h(start=h_start);
// SiemensPower.Units.SpecificHeatCapacity cp;
// SiemensPower.Units.Temperature T;
 SiemensPower.Units.MassFlowRate m_flow(start = m_flow_start);

protected
  Modelica.Blocks.Interfaces.RealInput m_flow_in_internal
    "Needed to connect to conditional connector";
  Modelica.Blocks.Interfaces.RealInput h_in_internal
    "Needed to connect to conditional connector";

public
  Interfaces.FluidPort_b port
    annotation (Placement(transformation(extent={{54,22},{74,42}})));
equation
  connect(m_flow_in, m_flow_in_internal);
  connect(hIn, h_in_internal);

  if not use_m_flow_in then
    m_flow_in_internal = m_flow;
  end if;
  if not use_h_in then
    h_in_internal = h;
  end if;

  port.h_outflow = h;
  port.p = p;
  port.m_flow = -m_flow;

  h = h_in_internal;
  m_flow = m_flow_in_internal;
  annotation (defaultComponentName="boundary",
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Rectangle(
          extent={{36,45},{100,-45}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={0,127,255}),
        Ellipse(
          extent={{-100,80},{60,-80}},
          lineColor={0,0,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-60,70},{60,0},{-60,-68},{-60,70}},
          lineColor={0,0,255},
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-54,32},{16,-30}},
          lineColor={255,0,0},
          textString="m"),
        Ellipse(
          extent={{-26,30},{-18,22}},
          lineColor={255,0,0},
          fillColor={255,0,0},
          fillPattern=FillPattern.Solid),
        Text(
          visible=use_m_flow_in,
          extent={{-185,132},{-45,100}},
          lineColor={0,0,0},
          textString="m_flow"),
        Text(
          visible=use_h_in,
          extent={{-113,72},{-73,38}},
          lineColor={0,0,0},
          textString="h"),
        Text(
          visible=use_X_in,
          extent={{-153,-44},{-33,-72}},
          lineColor={0,0,0},
          textString="X"),
        Text(
          visible=use_X_in,
          extent={{-155,-98},{-35,-126}},
          lineColor={0,0,0},
          textString="C"),
        Text(
          extent={{-150,110},{150,150}},
          textString="%name",
          lineColor={0,0,255})}),
    Window(
      x=0.45,
      y=0.01,
      width=0.44,
      height=0.65),
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics),
    Documentation(info="<html>
<p>
Models an ideal flow source, with prescribed values of flow rate, temperature and composition:
</p>
<ul>
<li> Prescribed mass flow rate.</li>
<li> Prescribed specific enthalpy.</li>
<li> Boundary composition (only for multi-substance or trace-substance flow).</li>
</ul>
<p>If <code>use_m_flow_in</code> is false (default option), the <code>m_flow</code> parameter
is used as boundary pressure, and the <code>m_flow_in</code> input connector is disabled; if <code>use_m_flow_in</code> is true, then the <code>m_flow</code> parameter is ignored, and the value provided by the input connector is used instead.</p>
<p>The same thing goes for the temperature and composition</p>
<p>
Note, that boundary temperature,
mass fractions and trace substances have only an effect if the mass flow
is from the boundary into the port. If mass is flowing from
the port into the boundary, the boundary definitions,
with exception of boundary flow rate, do not have an effect.
</p>
</html>"));
end MassFlowSource_h;
