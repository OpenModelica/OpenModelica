within ThermoSysPro.WaterSteam.PressureLosses;
model DynamicReliefValve "Dynamic relief valve"
  parameter ThermoSysPro.Units.DifferentialPressure dPOuvert=100000.0 "Pressure difference when the valve opens";
  parameter ThermoSysPro.Units.DifferentialPressure dPFerme=90000.0 "Pressure difference when the valve closes";
  parameter Real Cmin=0.01 "Minimum position of the valve";
  parameter ThermoSysPro.Units.Cv Cvmax=8005.42 "Maximum CV (active if mode_caract=0)";
  parameter Real caract[:,2]=[0,0;1,Cvmax] "Position vs. Cv characteristics (active if mode_caract=1)";
  parameter Real Ke=0.2 "Valve spring stiffness";
  parameter Real D=0 "Damping";
  parameter Modelica.SIunits.Mass m=0 "Valve mass";
  parameter Integer mode_caract=0 "0:linear characteristics - 1:characteristics is given by caract[]";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real Ouv "Valve position";
  ThermoSysPro.Units.Cv Cv "Cv";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate";
  ThermoSysPro.Units.DifferentialPressure deltaP "Singular pressure loss";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  ThermoSysPro.Units.AbsoluteTemperature T(start=290) "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure Pm(start=100000.0) "Fluid avreage pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=0.0, y=-98.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-98.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=1.0 "Small number for pressure loss equation";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
  Real der_Ouv "Valve position derivative";
  Real c "Valve position coefficient";
protected
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{0,0},{-30,-60},{30,-60},{0,0}}, fillPattern=FillPattern.Solid, fillColor={191,127,255}),Polygon(lineColor={0,0,255}, points={{0,0},{60,-30},{60,30},{0,0}}, fillPattern=FillPattern.Solid, fillColor={191,127,255}),Line(color={0,0,255}, points={{0,-60},{0,-98}}),Line(color={0,0,255}, points={{60,0},{90,0}}),Line(points={{0,0},{10,10},{-10,20},{10,28},{-10,40},{10,50},{-10,60},{10,70}}, color={191,127,255})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{0,0},{-30,-60},{30,-60},{0,0}}, fillPattern=FillPattern.Solid, fillColor={191,127,255}),Polygon(lineColor={0,0,255}, points={{0,0},{60,-30},{60,30},{0,0}}, fillPattern=FillPattern.Solid, fillColor={191,127,255}),Line(color={0,0,255}, points={{0,-60},{0,-98}}),Line(color={0,0,255}, points={{60,0},{90,0}}),Line(color={0,0,255}, points={{0,0},{10,10},{-10,20},{10,28},{-10,40},{10,50},{-10,60},{10,70}})}), Documentation(info="<html>
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
  if D > 0 then
    Ouv=c;
  end if;
  if m > 0 then
    der_Ouv=0;
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
  if dPOuvert > dPFerme then
    c=min(max((deltaP - dPFerme)/(dPOuvert - dPFerme), Cmin), 1);
  else
    c=if deltaP > dPOuvert then 1 else Cmin;
  end if;
  if D > 0 or m > 0 then
    der_Ouv=der(Ouv);
  else
    der_Ouv=0;
  end if;
  if D > 0 and m > 0 then
    Ouv + D/Ke*der_Ouv + m/Ke*der(der_Ouv)=c;
  elseif D > 0 then
    Ouv + D/Ke*der_Ouv=c;
  elseif m > 0 then
    Ouv + m/Ke*der(der_Ouv)=c;
  else
    Ouv=c;
  end if;
  deltaP*Cv*abs(Cv)=1733000000000.0*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho^2;
  if mode_caract == 0 then
    Cv=Ouv*Cvmax;
  elseif mode_caract == 1 then
    Cv=ThermoSysPro.Functions.Interpolation(Ouv, caract[:,1], caract[:,2]);
  else
    assert(false, "VanneReglante : mode de calcul du Cv incorrect");
  end if;
  Pm=(C1.P + C2.P)/2;
  pro=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pm, h, mode);
  T=pro.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
end DynamicReliefValve;
