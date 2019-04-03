within ThermoSysPro.WaterSteam.PressureLosses;
model Diaphragm "Diaphragm"
  parameter Real Ouv=0.5 "Diaphragm aperture";
  parameter Modelica.SIunits.Diameter D=0.2 "Diaphragm diameter";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real khi "Hydraulic pressure loss coefficient";
  ThermoSysPro.Units.DifferentialPressure deltaP "Pressure loss";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  Modelica.SIunits.ReynoldsNumber Re "Reynolds number";
  Modelica.SIunits.ReynoldsNumber Relim "Limit Reynolds number";
  Modelica.SIunits.Density rho "Fluid density";
  Modelica.SIunits.DynamicViscosity mu "Fluid dynamic viscosity";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure Pm "Fluid average pressure";
  ThermoSysPro.Units.SpecificEnthalpy h "Fluid specific enthalpy";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-40,100},{-40,20}}, color={0,191,0}, thickness=0.5),Line(points={{-40,-20},{-40,-100}}, color={0,191,0}, thickness=0.5),Line(points={{40,100},{40,18}}, color={0,191,0}, thickness=0.5),Line(points={{40,-20},{40,-100}}, color={0,191,0}, thickness=0.5)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-40,100},{-40,20}}, color={0,191,0}, thickness=0.5),Line(points={{-40,-20},{-40,-100}}, color={0,191,0}, thickness=0.5),Line(points={{40,100},{40,18}}, color={0,191,0}, thickness=0.5),Line(points={{40,-20},{40,-100}}, color={0,191,0}, thickness=0.5)}), Documentation(info="<html>
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
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=0.001 "Small number for pressure loss equation";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
equation
  C1.Q=C2.Q;
  C1.h=C2.h;
  C1.P - C2.P=deltaP;
  Q=C1.Q;
  h=C1.h;
  if continuous_flow_reversal then
    0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
  deltaP=8*khi*ThermoSysPro.Functions.ThermoSquare(Q, eps)/(pi^2*D^4*rho);
  assert(Ouv > 0 and not Ouv > 1, "Diaphragm: parameter Ouv should be such as 0 < Ouv <= 1");
  khi=((1.707 - Ouv)/Ouv)^2;
  Relim=100000.0;
  Re=4*abs(Q)/(pi*D*mu*Ouv);
  Pm=(C1.P + C2.P)/2;
  pro=ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);
  T=pro.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
  mu=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rho, T);
end Diaphragm;
