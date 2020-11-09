within NewDataReconciliationSimpleTests;
model LumpedStraightPipe "Lumped straight pipe (circular duct)"
 parameter Modelica.SIunits.Length L=10. "Pipe length";
  parameter Modelica.SIunits.Diameter D=0.2 "Pipe internal diameter";
  parameter Integer ntubes=1 "Number of pipes in parallel";
  parameter Real lambda=0.03
    "Friction pressure loss coefficient (active if lambda_fixed=true)";
  parameter Real rugosrel=0.0001
    "Pipe roughness (active if lambda_fixed=false)";
  parameter Modelica.SIunits.Position z1=0 "Inlet altitude";
  parameter Modelica.SIunits.Position z2=0 "Outlet altitude";
  parameter Boolean lambda_fixed=true
    "true: lambda given by parameter - false: lambde computed using Idel'Cik correlation";
  parameter Boolean inertia=false
    "true: momentum balance equation with inertia - false: without inertia";
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
  parameter Modelica.SIunits.Area A=ntubes*pi*D^2/4
    "Pipes cross-sectional area (circular duct is assumed)";
  parameter Modelica.SIunits.Area Pw=ntubes*pi*D
    "Pipes wetted perimeter (circular duct is assumed)";

public
  Real khi "Hydraulic pressure loss coefficient";
  ThermoSysPro.Units.DifferentialPressure deltaPf "Friction pressure loss";
  ThermoSysPro.Units.DifferentialPressure deltaP "Total pressure loss";
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow rate";
  Modelica.SIunits.ReynoldsNumber Re "Reynolds number";
  Modelica.SIunits.ReynoldsNumber Relim "Limit Reynolds number";
  Real lam "Friction pressure loss coefficient";
  Modelica.SIunits.Density rho "Fluid density";
  Modelica.SIunits.DynamicViscosity mu "Fluid dynamic viscosity";
  Modelica.SIunits.Temperature T "Fluid temperature";
  Modelica.SIunits.AbsolutePressure Pm "Fluid average pressure";
  Modelica.SIunits.SpecificEnthalpy h "Fluid specific enthalpy";

public
  ThermoSysPro.WaterSteam.Connectors.FluidInlet C1 annotation (Placement(transformation(extent={{-110,
            -10},{-90,10}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C2
                          annotation (Placement(transformation(extent={{90,-10},
            {110,10}}, rotation=0)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro
    annotation (Placement(transformation(extent={{-100,78},{-80,98}}, rotation=
            0)));
initial equation
  if inertia then
    der(Q) = 0;
  end if;

equation
  C1.h = C2.h;
  C1.Q = C2.Q;

  C1.P - C2.P = deltaP;

  h = C1.h;
  Q = C1.Q;

  /* Flow reversal */
  if continuous_flow_reversal then
    h = ThermoSysPro.Functions.SmoothCond(Q, C1.h_vol, C2.h_vol, 1);
  else
    0 = if (Q > 0) then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;

  /* Pressure loss */
  if inertia then
    deltaP = deltaPf + rho*g*(z2 - z1) + L/A*der(Q);
  else
    deltaP = deltaPf + rho*g*(z2 - z1);
  end if;

  deltaPf = khi*ThermoSysPro.Functions.ThermoSquare(Q, eps)/(2*A^2*rho);

  /* Darcy-Weisbach formula (Idel'cik p. 55). Quadratic flow regime is assumed and Re > 4000 (Re > Relim). */
  khi = lam*L/D;

  if lambda_fixed then
    lam = lambda;
  else
    if (rugosrel > 0.00005) then
      lam = 1/(2*Modelica.Math.log10(3.7/rugosrel))^2;
    else
      lam = if noEvent(Re > 0) then 1/(1.8*Modelica.Math.log10(Re) - 1.64)^2 else 0;
    end if;
  end if;

  Relim = if (rugosrel > 0.00005) then max(560/rugosrel, 2.e5) else 4000;
  Re = 4*abs(Q)/(Pw*mu);

  /* Fluid thermodynamic properties */
  Pm = (C1.P + C2.P)/2;

  pro = ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);

  T = pro.T;

  if (p_rho > 0) then
    rho = p_rho;
  else
    rho = pro.d;
  end if;

  mu = ThermoSysPro.Properties.Fluid.DynamicViscosity_Ph(Pm,h,fluid,mode,0.1,0.1,0.1,0);

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Rectangle(
          extent={{-100,20},{100,-20}},
          lineColor={28,108,200},
          fillColor={85,170,255},
          fillPattern=FillPattern.Solid)}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Rectangle(
          extent={{-100,20},{100,-20}},
          lineColor={28,108,200},
          fillColor={85,170,255},
          fillPattern=FillPattern.Solid)}),
    Window(
      x=0.06,
      y=0.08,
      width=0.82,
      height=0.65),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2019</b> </p>
<p><b>ThermoSysPro Version 3.2</h4>
<p>This component model is documented in Sect. 13.5 of the <a href=\"https://www.springer.com/us/book/9783030051044\">ThermoSysPro book</a>. </h4>
</html>",
   revisions="<html>
<p><u><b>Authors</b></u></p>
<ul>
<li>Daniel Bouskela</li>
<li>Baligh El Hefni </li>
</ul>
</html>"));
end LumpedStraightPipe;
