within DataReconciliationSimpleTests.QPLib.PressureLosses;
model PipePressureLoss "Pipe generic pressure loss"
  parameter Real K=10 "Friction pressure loss coefficient";
  parameter Modelica.SIunits.Position z1=0 "Inlet altitude";
  parameter Modelica.SIunits.Position z2=0 "Outlet altitude";
  parameter Boolean continuous_flow_reversal=false
    "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0
    "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";

protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n
    "Gravity constant";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=1.e-3 "Small number for pressure loss equation";
  parameter Modelica.SIunits.MassFlowRate Qeps=1.e-3
    "Small mass flow for continuous flow reversal";

public
  ThermoSysPro.Units.DifferentialPressure deltaPf "Friction pressure loss";
  ThermoSysPro.Units.DifferentialPressure deltaPg "Gravity pressure loss";
  ThermoSysPro.Units.DifferentialPressure deltaP "Total pressure loss";
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow rate";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  Modelica.SIunits.Temperature T(start=290) "Fluid temperature";
  Modelica.SIunits.AbsolutePressure Pm(start=1.e5) "Average fluid pressure";
  Modelica.SIunits.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";

  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
    "Propriétés de l'eau"
    annotation (Placement(transformation(extent={{-100,80},{-80,102}}, rotation=
           0)));
public
  ThermoSysPro.WaterSteam.Connectors.FluidInlet C1 annotation (Placement(
        transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C2 annotation (Placement(
        transformation(extent={{90,-10},{110,10}}, rotation=0)));

equation
  C1.P - C2.P = deltaP;
  C2.Q = C1.Q;
  C2.h = C1.h;

  h = C1.h;
  Q = C1.Q;

  /* Flow reversal */
  if continuous_flow_reversal then
    0 = noEvent(if (Q > Qeps) then C1.h - C1.h_vol else if (Q < -Qeps) then
      C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi
      *Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0 = if (Q > 0) then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;

  /* Pressure loss */
  deltaPf = K*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;
  deltaPg = rho*g*(z2 - z1);
  deltaP = deltaPf + deltaPg;

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
        grid={2,2}), graphics={Rectangle(
          extent={{-100,20},{100,-20}},
          lineColor={0,0,255},
          fillColor={85,255,85},
          fillPattern=FillPattern.Solid), Text(
          extent={{-12,14},{16,-14}},
          lineColor={0,0,255},
          fillColor={85,255,85},
          fillPattern=FillPattern.Solid,
          textString=
               "K")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Rectangle(
          extent={{-100,20},{100,-20}},
          lineColor={0,0,255},
          fillColor={85,255,85},
          fillPattern=FillPattern.Solid), Text(
          extent={{-12,14},{16,-14}},
          lineColor={0,0,255},
          fillColor={85,255,85},
          fillPattern=FillPattern.Solid,
          textString=
               "K")}),
    Window(
      x=0.11,
      y=0.04,
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
    Daniel Bouskela</li>
</ul>
</html>
"));
end PipePressureLoss;
