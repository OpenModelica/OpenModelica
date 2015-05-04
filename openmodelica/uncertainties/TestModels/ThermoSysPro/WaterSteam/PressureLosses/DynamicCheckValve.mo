within ThermoSysPro.WaterSteam.PressureLosses;
model DynamicCheckValve "Dynamic check valve"
  parameter ThermoSysPro.Units.Cv Cvmax=8005.42 "Maximum CV";
  parameter Real caract[:,2]=[0,0;1,Cvmax] "Position vs. Cv characteristics (active if mode_caract=1)";
  parameter Modelica.SIunits.MomentOfInertia J=1 "Flap moment of inertia";
  parameter Real Ke=0.2 "Flap spring stiffness";
  parameter Real Kf1=0 "Flap friction law coefficient #1";
  parameter Real Kf2=100 "Flap friction law coefficient #2";
  parameter Real n=5 "Flap friction law exponent";
  parameter Modelica.SIunits.Mass m=1 "Flap mass";
  parameter Modelica.SIunits.Area A=1 "Flap hydraulic area";
  parameter Integer mode_caract=0 "0:linear characteristics - 1:characteristics is given by caract[]";
  parameter Boolean permanent_meca=true "true: start from steady state - false: start from 0";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Boolean libre(start=true) "Indicator whether the flap is free to move in both directions";
  Modelica.SIunits.Torque Cp "Gravity torque";
  Modelica.SIunits.Torque Cr "Spring torque";
  Modelica.SIunits.Torque Cf "Friction torque";
  Modelica.SIunits.Torque Ch "Hydraulic torque";
  Modelica.SIunits.Torque Ct "Total torque";
  Modelica.SIunits.Angle theta(start=theta_m) "Flap aperture angle";
  Modelica.SIunits.AngularVelocity w "Flap angular speed";
  Modelica.SIunits.AngularAcceleration a "Flap angular acceleration";
  Real Ouv "Valve position";
  ThermoSysPro.Units.Cv Cv(start=Cvmax) "Cv";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate";
  ThermoSysPro.Units.DifferentialPressure deltaP "Singular pressure loss";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  ThermoSysPro.Units.AbsoluteTemperature T(start=290) "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure Pm(start=100000.0) "Fluid average pressrue";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  parameter Real eps=0.001 "Small number for pressure loss equation";
  parameter Modelica.SIunits.Radius r=sqrt(A/pi) "Flap radius";
  parameter Modelica.SIunits.Angle theta_min=0 "Minimum flap aperture angle";
  parameter Modelica.SIunits.Angle theta_max=pi/2 "Maximum flap aperture angle";
  parameter Modelica.SIunits.Angle theta_m=(theta_min + theta_max)/2;
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
protected
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-70,70},{-50,50}}, fillPattern=FillPattern.Solid, lineColor={191,127,255}, fillColor={191,127,255}),Line(points={{-60,-60},{-60,60},{60,-60},{60,60}}, color={191,127,255}, thickness=0.5),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{60,0},{100,0}}),Text(lineColor={0,0,255}, extent={{-28,80},{32,20}}, textString="D")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-70,70},{-50,50}}, fillPattern=FillPattern.Solid, lineColor={191,127,255}, fillColor={191,127,255}),Line(points={{-60,-60},{-60,60},{60,-60},{60,60}}, color={191,127,255}, thickness=0.5),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{60,0},{100,0}}),Text(lineColor={0,0,255}, extent={{-28,80},{32,20}}, textString="D")}), Documentation(info="<html>
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
initial equation
  if permanent_meca then
    der(theta)=0;
    der(w)=0;
  else
    theta=theta_m;
    w=0;
  end if;
equation
  C1.h=C2.h;
  C1.Q=C2.Q;
  h=C1.h;
  Q=C1.Q;
  deltaP=C1.P - C2.P;
  if continuous_flow_reversal then
    0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
  Ouv=1 - cos(theta);
  w=der(theta);
  a=der(w);
  Cp=-m*g*r*sin(theta);
  Cr=Ke*(theta_max - theta);
  Cf=-sign(w)*(Kf1 + Kf2*abs(w)^n);
  Ch=deltaP*r*A;
  Ct=Cp + Cr + Cf + Ch;
  libre=theta > theta_min and theta < theta_max or theta <= theta_m and Ct > 0 or theta >= theta_m and Ct < 0;
  if libre then
    J*a=Ct;
  else
    a=0;
  end if;
  when {theta <= theta_min,theta >= theta_max} then
    reinit(w, 0);
  end when;
  deltaP*Cv*abs(Cv)=1733000000000.0*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho^2;
  if mode_caract == 0 then
    Cv=Ouv*Cvmax;
  elseif mode_caract == 1 then
    Cv=ThermoSysPro.Functions.Interpolation(Ouv, caract[:,1], caract[:,2]);
  else
    assert(false, "ClapetDyn : mode de calcul du Cv incorrect");
  end if;
  Pm=(C1.P + C2.P)/2;
  pro=ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);
  T=pro.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
end DynamicCheckValve;
