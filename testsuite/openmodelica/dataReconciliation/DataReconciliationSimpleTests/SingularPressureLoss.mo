within DataReconciliationSimpleTests;
model SingularPressureLoss "Singular pressure loss"
  parameter Real K=1.e-4 "Pressure loss coefficient";
  parameter Boolean flow_reversal=true "true: with flow reversal - false: without flow reversal";
  parameter Boolean continuous_flow_reversal=false
    "true: continuous flow reversal - false: discontinuous flow reversal (active if flow_reversal=true)";
  parameter Boolean positive_flow=true "true: positive flows are assumed - false: negative flows are assumed (active if flow_reversal = false)";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0
    "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";

protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=1.e-3 "Small number for pressure loss equation";
  parameter Modelica.SIunits.MassFlowRate Qeps=1.e-3
    "Small mass flow for continuous flow reversal";

public
  ThermoSysPro.Units.DifferentialPressure deltaP "Singular pressure loss";
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow rate";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  Modelica.SIunits.Temperature T(start=290) "Fluid temperature";
  Modelica.SIunits.AbsolutePressure Pm(start=1.e5) "Average fluid pressure";
  Modelica.SIunits.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";

  ThermoSysPro.WaterSteam.Connectors.FluidInlet C1
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}}, rotation=
           0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C2                annotation (Placement(transformation(
          extent={{90,-10},{110,10}}, rotation=0)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
    annotation (Placement(transformation(extent={{-100,80},{-80,100}}, rotation=
           0)));
equation

  C1.P - C2.P = deltaP;
  C2.Q = C1.Q;
  C2.h = C1.h;

  h = C1.h;
  Q = C1.Q;

  /* Flow reversal */
  if flow_reversal then
    if continuous_flow_reversal then
      h = ThermoSysPro.Functions.SmoothCond(Q, C1.h_vol, C2.h_vol, 1);
    else
      0 = if (Q > 0) then C1.h - C1.h_vol else C2.h - C2.h_vol;
    end if;
  else
    if positive_flow then
      0 = C1.h - C1.h_vol;
    else
      0 = C2.h - C2.h_vol;
    end if;
  end if;

  /* Pressure loss */
  deltaP = K*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;

  /* Fluid thermodynamic properties */
  Pm = (C1.P + C2.P)/2;

  pro = ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);

  T = pro.T;

  if (p_rho > 0) then
    rho = p_rho;
  else
    rho = pro.d;
  end if;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Polygon(
          points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,
              40}},
          lineColor={0,0,255},
          fillColor={128,255,0},
          fillPattern=FillPattern.Solid), Polygon(
          points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,
              -40},{-60,-40}},
          lineColor={0,0,255},
          fillColor={128,255,0},
          fillPattern=FillPattern.Solid)}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Polygon(
          points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,
              40}},
          lineColor={0,0,255},
          fillColor={128,255,0},
          fillPattern=FillPattern.Solid), Polygon(
          points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,
              -40},{-60,-40}},
          lineColor={0,0,255},
          fillColor={128,255,0},
          fillPattern=FillPattern.Solid)}),
    Window(
      x=0.09,
      y=0.2,
      width=0.66,
      height=0.69),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
<p><b>ThermoSysPro Version 2.0</b></p>
<p>This component model is documented in Sect. 13.4 of the <a href=\"https://www.springer.com/us/book/9783030051044\">ThermoSysPro book</a>. </h4>
</HTML>
", revisions="<html>
<p><u><b>Authors</b></u></p>
<ul>
<li>Baligh El Hefni</li>
<li>Daniel Bouskela </li>
</ul>
</html>"));
end SingularPressureLoss;
