within ThermoSysPro.WaterSteam.Machines;
model DynamicCentrifugalPump "Dynamic centrifugal pump"
  parameter ThermoSysPro.Units.RotationVelocity VRotn=1400 "Nominal rotational speed";
  parameter ThermoSysPro.Units.RotationVelocity VRot0=0 "Initial rotational speed (active if steady_state_mech=false)";
  parameter Modelica.SIunits.Volume V=1 "Pump volume (only if dynamic_energy_balance = true)";
  parameter Modelica.SIunits.MomentOfInertia J=10 "Pump moment of inertia";
  parameter Real Cf0=10 "Mechanical friction coefficient";
  parameter Boolean steady_state_mech=true "true: start from steady state - false: start from VRot0";
  parameter Boolean dynamic_energy_balance=true "true: dynamic energy balance equation - false: static energy balance equation";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Real a1=-88.67 "x^2 coef. of the pump characteristics hn = f(vol_flow) (s2/m5)";
  parameter Real a2=0 "x coef. of the pump characteristics hn = f(vol_flow) (s/m2)";
  parameter Real a3=43.15 "Constant coef. of the pump characteristics hn = f(vol_flow) (m)";
  parameter Real b1=-3.7751 "x^2 coef. of the pump efficiency characteristics rh = f(vol_flow) (s2/m6)";
  parameter Real b2=3.61 "x coef. of the pump efficiency characteristics rh = f(vol_flow) (s/m3)";
  parameter Real b3=-0.0075464 "Constant coef. of the pump efficiency characteristics rh = f(vol_flow) (s.u.)";
  Real rh "Hydraulic efficiency";
  Modelica.SIunits.Height hn(start=10) "Pump head";
  ThermoSysPro.Units.RotationVelocity VRot(start=VRotn) "Rotational speed";
  Modelica.SIunits.AngularVelocity w "Angular speed";
  Real R "Ratio VRot/VRotn (s.u.)";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate";
  Modelica.SIunits.VolumeFlowRate Qv(start=0.5) "Volume flow rate";
  Modelica.SIunits.Torque Cm "Motor torque";
  Modelica.SIunits.Torque Ch "Hydraulic torque";
  Modelica.SIunits.Torque Cf "Mechanical friction torque";
  Modelica.SIunits.Power Wm "Motor power";
  Modelica.SIunits.Power Wh "Hydraulic power";
  Modelica.SIunits.Power Wf "Mechanical friction power";
  Modelica.SIunits.Density rho "Fluid density";
  ThermoSysPro.Units.DifferentialPressure deltaP "Pressure variation between the outlet and the inlet";
  ThermoSysPro.Units.SpecificEnthalpy deltaH "Specific enthalpy variation between the outlet and the inlet";
  ThermoSysPro.Units.AbsolutePressure Pm "Fluid average pressure";
  ThermoSysPro.Units.SpecificEnthalpy h "Fluid average specific enthalpy";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Line(points={{-80,0},{80,0}}, color={0,0,0}),Line(points={{80,0},{2,60}}, color={0,0,0}),Line(points={{80,0},{0,-60}}, color={0,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-80,0},{80,0}}),Line(color={0,0,255}, points={{80,0},{2,60}}),Line(color={0,0,255}, points={{80,0},{0,-60}}),Text(lineColor={0,0,255}, extent={{-28,-54},{32,-106}}, textString="Q"),Ellipse(extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={127,191,255}),Line(points={{80,0},{2,60}}, color={0,0,0}),Line(points={{-80,0},{80,0}}, color={0,0,0}),Line(points={{80,0},{0,-60}}, color={0,0,0})}), Documentation(info="<html>
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
  ThermoSysPro.ElectroMechanics.Connectors.MechanichalTorque M annotation(Placement(transformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=1e-06 "Small number";
  parameter Real rhmin=0.05 "Minimum efficiency to avoid zero crossings";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
initial equation
  if steady_state_mech then
    der(w)=0;
  else
    w=pi/30*VRot0;
  end if;
  if dynamic_energy_balance then
    der(h)=0;
  end if;
equation
  Cm=M.Ctr;
  w=M.w;
  deltaP=C2.P - C1.P;
  deltaH=C2.h - C1.h;
  C1.Q=C2.Q;
  Q=C1.Q;
  Q=Qv*rho;
  deltaP=rho*g*hn;
  if continuous_flow_reversal then
    0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
  if dynamic_energy_balance then
    V*rho*der(h)=-Q*deltaH + Wh + Wf;
  else
    0=-Q*deltaH + Wh + Wf;
  end if;
  VRot=30/pi*w;
  R=VRot/VRotn;
  hn=noEvent(a1*Qv*abs(Qv) + a2*Qv*R + a3*R*abs(R));
  rh=noEvent(max(if abs(R) > eps then b1*Qv^2/R^2 + b2*Qv/R + b3 else b3, rhmin));
  J*der(w)=Cm - Cf - Ch;
  Wm=Cm*w;
  Wh=Qv*deltaP/rh;
  Wh=Ch*w;
  Cf=noEvent(if abs(R) < 1 then ThermoSysPro.Functions.SmoothSign(R)*Cf0*(1 - abs(R)) else 0);
  Wf=Cf*w;
  Pm=(C1.P + C2.P)/2;
  h=(C1.h + C2.h)/2;
  pro=ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
end DynamicCentrifugalPump;
