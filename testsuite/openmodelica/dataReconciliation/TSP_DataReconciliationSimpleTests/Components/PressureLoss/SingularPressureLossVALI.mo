within TSP_DataReconciliationSimpleTests.Components.PressureLoss;
model SingularPressureLossVALI
  "Singular pressure loss"
  parameter Modelica.Units.SI.MassFlowRate Qnom=535
    "Nominal mass flow rate";
  parameter Modelica.Units.SI.Pressure deltaPnom=0.5e5
    "Nominal pressure loss";
  parameter Real CoeffDeltaP=1
    "Ponderation of the pressure loss equation";
  parameter Modelica.Units.SI.SpecificHeatCapacity cp=4200
    "Specific heat capacity";
  parameter Real b=190e-5;
  parameter Boolean flow_reversal=false
    "true: with flow reversal - false: without flow reversal";
  parameter Boolean continuous_flow_reversal=false
    "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Boolean positive_flow=true
    "true: positive flows are assumed - false: negative flows are assumed (active if flow_reversal = false)";
protected
  constant Real pi=Modelica.Constants.pi
    "pi";
  parameter Real eps=1.e-3
    "Small number for pressure loss equation";
  parameter Modelica.Units.SI.MassFlowRate Qeps=1.e-3
    "Small mass flow for continuous flow reversal";
public
  Modelica.Units.SI.Pressure deltaP(
    start=deltaPnom)
    "Singular pressure loss";
  Modelica.Units.SI.MassFlowRate Q(
    start=1)
    "Mass flow rate";
  Modelica.Units.SI.AbsolutePressure Pm(
    start=1.e5)
    "Average fluid pressure";
  Modelica.Units.SI.SpecificEnthalpy h(
    start=100000)
    "Fluid specific enthalpy";
  Modelica.Units.SI.Temperature T(
    start=290)
    "Fluid temperature";
  ThermoSysPro.WaterSteam.Connectors.FluidInlet C1(
    h(
      start=1e5),
    h_vol(
      start=1e5),
    Q(
      start=1))
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C2(
    h(
      start=1e5),
    h_vol(
      start=1e5),
    Q(
      start=1))
    annotation (Placement(transformation(extent={{90,-10},{110,10}},rotation=0)));
equation
  C1.P-C2.P=deltaP;
  C2.Q=C1.Q;
  C2.h=C1.h;
  Q=C1.Q;
  h=C1.h;

  /* Flow reversal */
  if flow_reversal then
    if continuous_flow_reversal then
      0=noEvent(
        if Q > Qeps then
          C1.h-C1.h_vol
        else
          if Q <(-Qeps) then
            C2.h-C2.h_vol
          else
            C1.h-0.5*((C1.h_vol-C2.h_vol)*Modelica.Math.sin(
              pi*Q/2/Qeps)+C1.h_vol+C2.h_vol));
else
  0=
    if Q > 0 then
      C1.h-C1.h_vol
    else
      C2.h-C2.h_vol;
end if;
else
if positive_flow then
  0=C1.h-C1.h_vol;
else
  0=C2.h-C2.h_vol;
end if;
end if;

/* Pressure loss */

//deltaP = CoeffDeltaP * deltaPnom * ThermoSysPro.Functions.ThermoSquare(Q / Qnom, eps);
deltaP=CoeffDeltaP*deltaPnom*Q/Qnom*abs(
Q/Qnom);
Pm=(C1.P+C2.P)/2;
h=cp*(T-273.16)+b*Pm;
annotation (
Diagram(
  coordinateSystem(
    preserveAspectRatio=false,
    extent={{-100,-100},{100,100}},
    grid={2,2}),
  graphics={
    Polygon(
      points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,40}},
      lineColor={0,0,255},
      fillColor={128,255,0},
      fillPattern=FillPattern.Solid),
    Polygon(
      points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}},
      lineColor={0,0,255},
      fillColor={128,255,0},
      fillPattern=FillPattern.Solid),
    Text(
      extent={{-48,88},{52,40}},
      lineColor={0,0,255},
      textString="VALI")}),
Icon(
  coordinateSystem(
    preserveAspectRatio=false,
    extent={{-100,-100},{100,100}},
    grid={2,2}),
  graphics={
    Polygon(
      points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,40}},
      lineColor={0,0,255},
      fillColor={128,255,0},
      fillPattern=FillPattern.Solid),
    Polygon(
      points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}},
      lineColor={0,0,255},
      fillColor={128,255,0},
      fillPattern=FillPattern.Solid),
    Text(
      extent={{-48,88},{52,40}},
      lineColor={0,0,255},
      textString="VALI")}),
Window(
  x=0.09,
  y=0.2,
  width=0.66,
  height=0.69),
Documentation(
  info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
    ",
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
end SingularPressureLossVALI;
