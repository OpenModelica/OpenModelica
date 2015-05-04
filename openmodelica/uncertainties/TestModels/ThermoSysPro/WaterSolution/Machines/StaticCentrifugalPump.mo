within ThermoSysPro.WaterSolution.Machines;
model StaticCentrifugalPump "Water solution static centrifugal pump"
  parameter ThermoSysPro.Units.RotationVelocity VRot=1400 "Rotational speed";
  parameter ThermoSysPro.Units.RotationVelocity VRotn=1400 "Nominal rotational speed";
  parameter Real rm=0.85 "Product of the pump mechanical and electrical efficiencies";
  parameter Boolean adiabatic_compression=false "true: adiabatic compression - false: non adiabatic compression";
  parameter Modelica.SIunits.Density rho=1000 "Fluid density";
  parameter Real a1=-88.67 "x^2 coef. of the pump characteristics hn = f(vol_flow) (s2/m5)";
  parameter Real a2=0 "x coef. of the pump characteristics hn = f(vol_flow) (s/m2)";
  parameter Real a3=43.15 "Constant coef. of the pump characteristics hn = f(vol_flow) (m)";
  parameter Real b1=-3.7751 "x^2 coef. of the pump efficiency characteristics rh = f(vol_flow) (s2/m6)";
  parameter Real b2=3.61 "x coef. of the pump efficiency characteristics rh = f(vol_flow) (s/m3)";
  parameter Real b3=-0.0075464 "Constant coef. of the pump efficiency characteristics rh = f(vol_flow) (s.u.)";
  Real rh "Hydraulic efficiency";
  Modelica.SIunits.Length hn(start=10) "Pump head";
  Real R "Ratio VRot/VRotn (s.u.)";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow";
  Modelica.SIunits.VolumeFlowRate Qv(start=0.5) "Volumetric flow";
  Modelica.SIunits.Power Wh "Hydraulic power";
  Modelica.SIunits.Power Wm "Motor power";
  ThermoSysPro.Units.AbsolutePressure deltaP "Pressure difference between the outlet and the inlet";
  ThermoSysPro.Units.SpecificEnthalpy h1 "Fluid specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy h2 "Fluid specific enthalpy at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy deltaH "Specific enthalpy variation between the outlet and the inlet";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillColor={223,159,159}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-80,0},{80,0}}),Line(color={0,0,255}, points={{80,0},{2,60}}),Line(color={0,0,255}, points={{80,0},{0,-60}})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillColor={223,159,159}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-80,0},{80,0}}),Line(color={0,0,255}, points={{80,0},{2,60}}),Line(color={0,0,255}, points={{80,0},{0,-60}})}), Documentation(info="<html>
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
</html>
"));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical commandePompe annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal VRotation annotation(Placement(transformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  parameter Real eps=1e-06 "Small number";
  parameter Real rhmin=0.05 "Minimum efficiency to avoid zero crossings";
equation
  if cardinality(commandePompe) == 0 then
    commandePompe.signal=true;
  end if;
  if cardinality(VRotation) == 0 then
    VRotation.signal=VRot;
  end if;
  deltaP=C2.P - C1.P;
  deltaH=h2 - h1;
  deltaP=rho*g*hn;
  if adiabatic_compression then
    deltaH=0;
  else
    deltaH=g*hn/rh;
  end if;
  C1.Xh2o=C2.Xh2o;
  C1.Q=C2.Q;
  Q=C1.Q;
  Q=Qv*rho;
  R=if commandePompe.signal then VRotation.signal/VRotn else 0;
  hn=noEvent(a1*Qv*abs(Qv) + a2*Qv*R + a3*R^2);
  rh=noEvent(max(if abs(R) > eps then b1*Qv^2/R^2 + b2*Qv/R + b3 else b3, rhmin));
  Wm=Q*deltaH/rm;
  Wh=Qv*deltaP/rh;
  h1=ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(C1.T, C1.Xh2o);
  h2=ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(C2.T, C2.Xh2o);
end StaticCentrifugalPump;
