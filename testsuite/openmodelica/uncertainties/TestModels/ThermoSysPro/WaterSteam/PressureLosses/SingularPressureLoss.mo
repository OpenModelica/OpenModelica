within ThermoSysPro.WaterSteam.PressureLosses;
model SingularPressureLoss "Singular pressure loss"
  parameter Real K=1000.0 "Pressure loss coefficient";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.DifferentialPressure deltaP "Singular pressure loss";
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow rate";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  ThermoSysPro.Units.AbsoluteTemperature T(start=290) "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure Pm(start=100000.0) "Average fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,255,0}),Polygon(points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,255,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,255,0}),Polygon(points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,255,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
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
  C1.P - C2.P=deltaP;
  C2.Q=C1.Q;
  C2.h=C1.h;
  h=C1.h;
  Q=C1.Q;
  if continuous_flow_reversal then
    0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
  deltaP=K*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;
  Pm=(C1.P + C2.P)/2;
  pro=ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);
  T=pro.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
end SingularPressureLoss;
