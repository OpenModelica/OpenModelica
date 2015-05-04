within ThermoSysPro.WaterSteam.Volumes;
model DegasifierVolume "Degazifier volume"
  parameter Modelica.SIunits.Volume V=160 "Degazifier volume";
  parameter Modelica.SIunits.Volume Vmax=10 "Maximum volume of the liquid in the basins";
  parameter Modelica.SIunits.SpecificHeatCapacity Cpmetal=460 "Metal specific heat";
  parameter Modelica.SIunits.Mass Mmetal=10869 "Metal mass";
  parameter ThermoSysPro.Units.AbsolutePressure P0=100000.0 "Initial fluid pressure (active if steady_state=false)";
  parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000.0 "Initial fluid specific enthalpy (active if steady_state=false)";
  parameter Boolean steady_state=true "true: start from steady state - false: start from (P0, h0)";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Modelica.SIunits.Power W "Thermal power exchanged between the liquid and the basins";
  ThermoSysPro.Units.AbsoluteTemperature Tl "Saturation temperature of the liquid in the basins";
  Real x "Vapor mass fraction";
  ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Average fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  Modelica.SIunits.MassFlowRate BQ "Right hand side of the mass balance equation";
  Modelica.SIunits.Power BH "Right hand side of the energy balance equation";
  Real rhols;
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-102,60},{100,-60}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, fillColor={127,191,255})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-102,60},{100,-60}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,191,255})}), Documentation(info="<html>
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
</ul>
</html>
"));
  Connectors.FluidInlet Ce1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce2 annotation(Placement(transformation(x=-40.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-40.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs annotation(Placement(transformation(x=-40.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-40.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce3 annotation(Placement(transformation(x=40.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce4 annotation(Placement(transformation(x=40.0, y=-58.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=-58.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
initial equation
  if steady_state then
    der(P)=0;
    der(h)=0;
  else
    P=P0;
    h=h0;
  end if;
equation
  assert(V > 0, "Volume non strictement positif");
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
  if cardinality(Ce3) == 0 then
    Ce3.Q=0;
    Ce3.h=100000.0;
    Ce3.b=true;
  end if;
  if cardinality(Ce4) == 0 then
    Ce4.Q=0;
    Ce4.h=100000.0;
    Ce4.b=true;
  end if;
  if cardinality(Cs) == 0 then
    Cs.Q=0;
    Cs.h=100000.0;
    Cs.a=true;
  end if;
  P=Ce1.P;
  P=Ce2.P;
  P=Ce3.P;
  P=Ce4.P;
  P=Cs.P;
  BQ=Ce1.Q + Ce2.Q + Ce3.Q + Ce4.Q - Cs.Q;
  V*(pro.ddph*der(P) + pro.ddhp*der(h))=BQ;
  BH=Ce1.Q*Ce1.h + Ce2.Q*Ce2.h + Ce3.Q*Ce3.h + Ce4.Q*Ce4.h - Cs.Q*Cs.h - W;
  V*((h*pro.ddph - 1)*der(P) + (h*pro.ddhp + rho)*der(h))=BH;
  Ce1.h_vol=h;
  Ce2.h_vol=h;
  Ce3.h_vol=h;
  Ce4.h_vol=h;
  Cs.h_vol=h;
  W=Mmetal*Cpmetal*der(P)/lsat.pt;
  pro=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, h, mode);
  x=pro.x;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
  lsat=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P);
  rhols=lsat.rho;
  Tl=lsat.T;
end DegasifierVolume;
