within ThermoSysPro.FlueGases.Machines;
model StaticFan "Static fan"
  parameter ThermoSysPro.Units.RotationVelocity VRot=1400 "Rotational speed";
  parameter ThermoSysPro.Units.RotationVelocity VRotn=1400 "Nominal rotational speed";
  parameter Real rm=0.85 "Product of the pump mechanical and electrical efficiencies";
  parameter Boolean adiabatic_compression=false "true: adiabatic compression - false: non adiabatic compression";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Real a1=-52.04 "x^2 coef. of the pump characteristics hn = f(vol_flow) (s2/m5)";
  parameter Real a2=-71.735 "x coef. of the pump characteristics hn = f(vol_flow) (s/m2)";
  parameter Real a3=45.59 "Constant coef. of the pump characteristics hn = f(vol_flow) (m)";
  parameter Real b1=-8.4818 "x^2 coef. of the pump efficiency characteristics rh = f(vol_flow) (s2/m6)";
  parameter Real b2=4.6593 "x coef. of the pump efficiency characteristics rh = f(vol_flow) (s/m3)";
  parameter Real b3=-0.1533 "Constant coef. of the pump efficiency characteristics rh = f(vol_flow) (s.u.)";
  Real rh(start=0.5) "Hydraulic efficiency";
  Modelica.SIunits.Length hn(start=10) "Pump head";
  Real R "Ratio VRot/VRotn (s.u.)";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow";
  Modelica.SIunits.VolumeFlowRate Qv(start=0.5) "Volumetric flow";
  Modelica.SIunits.Power Wh "Hydraulic power";
  Modelica.SIunits.Power Wm "Motor power";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  ThermoSysPro.Units.DifferentialPressure deltaP "Pressure variation between the outlet and the inlet";
  ThermoSysPro.Units.SpecificEnthalpy deltaH "Specific enthalpy variation between the outlet and the inlet";
  ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Fluid average pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid average specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy h1(start=100000) "Fluid specific enthalpy in";
  ThermoSysPro.Units.SpecificEnthalpy h2(start=100000) "Fluid specific enthalpy out";
  ThermoSysPro.Units.AbsoluteTemperature T(start=500) "Fluid temperature";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical commandeFan annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  Connectors.FlueGasesInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal VRotation annotation(Placement(transformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  parameter Real eps=1e-06 "Small number";
  parameter Real rhmin=0.05 "Minimum efficiency to avoid zero crossings";
equation
  if cardinality(commandeFan) == 0 then
    commandeFan.signal=true;
  end if;
  if cardinality(VRotation) == 0 then
    VRotation.signal=VRot;
  end if;
  C1.Xco2=C2.Xco2;
  C1.Xh2o=C2.Xh2o;
  C1.Xo2=C2.Xo2;
  C1.Xso2=C2.Xso2;
  deltaP=C2.P - C1.P;
  deltaH=h2 - h1;
  deltaP=rho*g*hn;
  if adiabatic_compression then
    deltaH=0;
  else
    deltaH=g*hn/rh;
  end if;
  C1.Q=C2.Q;
  Q=C1.Q;
  Q=Qv*rho;
  R=if commandeFan.signal then VRotation.signal/VRotn else 0;
  hn=noEvent(a1*Qv*abs(Qv) + a2*Qv*R + a3*R^2);
  rh=noEvent(max(if abs(R) > eps then b1*Qv^2/R^2 + b2*Qv/R + b3 else b3, rhmin));
  Wm=Q*deltaH/rm;
  Wh=Qv*deltaP/rh;
  P=(C1.P + C2.P)/2;
  h=(h1 + h2)/2;
  h=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, T, C2.Xco2, C2.Xh2o, C2.Xo2, C2.Xso2);
  h2=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, C2.T, C2.Xco2, C2.Xh2o, C2.Xo2, C2.Xso2);
  h1=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, C1.T, C2.Xco2, C2.Xh2o, C2.Xo2, C2.Xso2);
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=ThermoSysPro.Properties.FlueGases.FlueGases_rho(P, T, C2.Xco2, C2.Xh2o, C2.Xo2, C2.Xso2);
  end if;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}),Polygon(points={{-40,92},{40,92},{-40,-92},{40,-92},{-40,92}}, lineColor={0,0,255}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(points={{-92,40},{-92,-40},{92,40},{92,-40},{-92,40}}, lineColor={0,0,255}, fillColor={127,255,0}, fillPattern=FillPattern.Backward)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}),Polygon(points={{-40,92},{40,92},{-40,-92},{40,-92},{-40,92}}, lineColor={0,0,255}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(points={{-92,40},{-92,-40},{92,40},{92,-40},{-92,40}}, lineColor={0,0,255}, fillColor={127,255,0}, fillPattern=FillPattern.Backward)}), Documentation(info="<html>
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
<li>
    Baligh El Hefni</li>
</ul>
</html>
"), DymolaStoredErrors);
end StaticFan;
