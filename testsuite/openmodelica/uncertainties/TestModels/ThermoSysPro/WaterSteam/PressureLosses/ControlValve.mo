within ThermoSysPro.WaterSteam.PressureLosses;
model ControlValve "Control valve"
  parameter ThermoSysPro.Units.Cv Cvmax=8005.42 "Maximum CV (active if mode_caract=0)";
  parameter Real caract[:,2]=[0,0;1,Cvmax] "Position vs. Cv characteristics (active if mode_caract=1)";
  parameter Integer mode_caract=0 "0:linear characteristics - 1:characteristics is given by caract[]";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.Cv Cv(start=100) "Cv";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate";
  ThermoSysPro.Units.DifferentialPressure deltaP "Singular pressure loss";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  ThermoSysPro.Units.AbsoluteTemperature T(start=290) "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure Pm(start=100000.0) "Fluid average pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{40,40},{-40,40},{-40,56},{-38,74},{-32,84},{-20,94},{0,100},{20,94},{32,84},{38,72},{40,54},{40,40}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{0,-60},{40,40},{-40,40},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,-100},{0,-60},{-100,-20},{-100,-102},{-100,-100}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{0,-60},{100,-20},{100,-102},{0,-60},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,-100},{0,-60},{-100,-20},{-100,-102},{-100,-100}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{0,-60},{100,-20},{100,-102},{0,-60},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{0,-60},{40,40},{-40,40},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{40,40},{-40,40},{-40,56},{-38,74},{-32,84},{-20,94},{0,100},{20,94},{32,84},{38,72},{40,54},{40,40}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
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
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ouv annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=1.0 "Small number for pressure loss equation";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
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
  deltaP*Cv*abs(Cv)=1733000000000.0*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho^2;
  if mode_caract == 0 then
    Cv=Ouv.signal*Cvmax;
  elseif mode_caract == 1 then
    Cv=ThermoSysPro.Functions.Interpolation(Ouv.signal, caract[:,1], caract[:,2]);
  else
    assert(false, "ControlValve: invalid option");
  end if;
  Pm=(C1.P + C2.P)/2;
  pro=ThermoSysPro.Properties.Fluid.Ph(Pm, h, mode, fluid);
  T=pro.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
end ControlValve;
