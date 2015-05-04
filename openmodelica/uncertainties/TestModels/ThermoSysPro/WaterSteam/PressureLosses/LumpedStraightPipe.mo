within ThermoSysPro.WaterSteam.PressureLosses;
model LumpedStraightPipe "Lumped straight pipe (circular duct)"
  parameter Modelica.SIunits.Length L=10.0 "Pipe length";
  parameter Modelica.SIunits.Diameter D=0.2 "Pipe internal diameter";
  parameter Real lambda=0.03 "Friction pressure loss coefficient (active if lambda_fixed=true)";
  parameter Real rugosrel=0 "Pipe roughness (active if lambda_fixed=false)";
  parameter Modelica.SIunits.Position z1=0 "Inlet altitude";
  parameter Modelica.SIunits.Position z2=0 "Outlet altitude";
  parameter Boolean lambda_fixed=true "true: lambda given by parameter - false: lambde computed using Idel'Cik correlation";
  parameter Boolean inertia=false "true: momentum balance equation with inertia - false: without inertia";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real khi "Hydraulic pressure loss coefficient";
  ThermoSysPro.Units.DifferentialPressure deltaPf "Friction pressure loss";
  ThermoSysPro.Units.DifferentialPressure deltaP "Total pressure loss";
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow rate";
  Modelica.SIunits.ReynoldsNumber Re "Reynolds number";
  Modelica.SIunits.ReynoldsNumber Relim "Limit Reynolds number";
  Real lam "Friction pressure loss coefficient";
  Modelica.SIunits.Density rho "Fluid density";
  Modelica.SIunits.DynamicViscosity mu "Fluid dynamic viscosity";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure Pm "Fluid average pressure";
  ThermoSysPro.Units.SpecificEnthalpy h "Fluid specific enthalpy";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,20},{100,-20}}, fillColor={127,191,255}, fillPattern=FillPattern.Solid)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,20},{100,-20}}, fillColor={127,191,255}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
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
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=0.001 "Small number for pressure loss equation";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
  parameter Modelica.SIunits.Area A=pi*D^2/4 "Pipe cross-sectional area (circular duct is assumed)";
  parameter Modelica.SIunits.Diameter DH=D "Pipe hydraulic diameter (circular duct is assumed)";
  parameter Modelica.SIunits.Area Pw=pi*D "Pipe wetted perimeter (circular duct is assumed)";
equation
  C1.h=C2.h;
  C1.Q=C2.Q;
  C1.P - C2.P=deltaP;
  h=C1.h;
  Q=C1.Q;
  if continuous_flow_reversal then
    0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
  if inertia then
    deltaP=deltaPf + rho*g*(z2 - z1) + L/A*der(Q);
  else
    deltaP=deltaPf + rho*g*(z2 - z1);
  end if;
  deltaPf=khi*ThermoSysPro.Functions.ThermoSquare(Q, eps)/(2*A^2*rho);
  khi=lam*L/DH;
  if lambda_fixed then
    lam=lambda;
  else
    if rugosrel > 5e-05 then
      lam=1/(2*Modelica.Math.log10(3.7/rugosrel))^2;
    else
      lam=if noEvent(Re > 0) then 1/(1.8*Modelica.Math.log10(Re) - 1.64)^2 else 0;
    end if;
  end if;
  Relim=if rugosrel > 5e-05 then max(560/rugosrel, 200000.0) else 4000;
  Re=4*abs(Q)/(Pw*mu);
  Pm=(C1.P + C2.P)/2;
  pro=ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);
  T=pro.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
  mu=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rho, T);
end LumpedStraightPipe;
