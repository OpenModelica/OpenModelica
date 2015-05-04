within ThermoSysPro.WaterSteam.Volumes;
model VolumeBTh "Mixing volume with 2 inlets and 2 outlets and thermal input"
  parameter Modelica.SIunits.Volume V=1 "Volume";
  parameter ThermoSysPro.Units.AbsolutePressure P0=100000.0 "Initial fluid pressure (active if dynamic_mass_balance=true and steady_state=false)";
  parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000.0 "Initial fluid specific enthalpy (active if steady_state=false)";
  parameter Boolean dynamic_mass_balance=false "true: dynamic mass balance equation - false: static mass balance equation";
  parameter Boolean steady_state=true "true: start from steady state - false: start from (P0, h0)";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  Modelica.SIunits.MassFlowRate BQ "Right hand side of the mass balance equation";
  Modelica.SIunits.Power BH "Right hand side of the energybalance equation";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Line(color={0,0,255}, points={{-90,0},{90,0}}),Line(color={0,0,255}, points={{0,90},{0,-100}})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{0,90},{0,-100}}),Line(color={0,0,255}, points={{-90,0},{90,0}}),Ellipse(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillPattern=FillPattern.Solid, fillColor={127,191,255})}), Documentation(info="<html>
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
  ThermoSysPro.Thermal.Connectors.ThermalPort Cth annotation(Placement(transformation(x=0.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs1 annotation(Placement(transformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs2 annotation(Placement(transformation(x=0.0, y=-98.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-98.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
initial equation
  if steady_state then
    if dynamic_mass_balance then
      der(P)=0;
    end if;
    der(h)=0;
  else
    if dynamic_mass_balance then
      P=P0;
    end if;
    h=h0;
  end if;
equation
  assert(V > 0, "Volume non-positive");
  if cardinality(Ce1) == 0 then
    Ce1.Q=0;
    Ce1.h=100000.0;
    Ce1.b=true;
  end if;
  if cardinality(Ce2) == 0 then
    Ce2.Q=0;
    Ce2.h=100000.0;
    Ce2.b=true;
  end if;
  if cardinality(Cs1) == 0 then
    Cs1.Q=0;
    Cs1.h=100000.0;
    Cs1.a=true;
  end if;
  if cardinality(Cs2) == 0 then
    Cs2.Q=0;
    Cs2.h=100000.0;
    Cs2.a=true;
  end if;
  BQ=Ce1.Q + Ce2.Q - Cs1.Q - Cs2.Q;
  if dynamic_mass_balance then
    V*(pro.ddph*der(P) + pro.ddhp*der(h))=BQ;
  else
    0=BQ;
  end if;
  P=Ce1.P;
  P=Ce2.P;
  P=Cs1.P;
  P=Cs2.P;
  BH=Ce1.Q*Ce1.h + Ce2.Q*Ce2.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h + Cth.W;
  if dynamic_mass_balance then
    V*((h*pro.ddph - 1)*der(P) + (h*pro.ddhp + rho)*der(h))=BH;
  else
    V*rho*der(h)=BH;
  end if;
  Ce1.h_vol=h;
  Ce2.h_vol=h;
  Cs1.h_vol=h;
  Cs2.h_vol=h;
  pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);
  T=pro.T;
  Cth.T=T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
end VolumeBTh;
