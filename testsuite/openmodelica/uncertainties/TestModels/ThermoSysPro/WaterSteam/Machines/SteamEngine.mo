within ThermoSysPro.WaterSteam.Machines;
model SteamEngine
  parameter Real caract[:,2]=[0,0;1500000.0,20.0] "Engine charateristics Q=f(deltaP)";
  parameter Real eta_is=0.85 "Isentropic efficiency";
  parameter Real W_frot=0.0 "Power losses due to hydrodynamic friction (percent)";
  parameter Real eta_stato=1.0 "Efficiency to account for cinetic losses (<= 1) (s.u.)";
  parameter Integer mode_e=0 "Inlet IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_s=0 "Outlet IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Modelica.SIunits.Power W "Power produced by the engine";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  ThermoSysPro.Units.SpecificEnthalpy His "Fluid specific enthalpy after isentropic expansion";
  ThermoSysPro.Units.DifferentialPressure deltaP "Pressure loss";
  ThermoSysPro.Units.AbsolutePressure Pe(start=1000000.0) "Pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Ps(start=1000000.0) "Pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Te "Temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Ts "Temperature at the outlet";
  Real xm(start=1.0, min=0) "Average vapor mass fraction (n.u.)";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proe annotation(Placement(transformation(x=-70.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pros annotation(Placement(transformation(x=70.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-60,100},{-60,-100},{60,-100},{60,100},{-60,100}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Rectangle(lineColor={0,0,255}, extent={{-20,100},{20,12}}, fillPattern=FillPattern.Solid, fillColor={255,255,255}),Ellipse(lineColor={0,0,255}, extent={{-22,-16},{30,-66}}, fillColor={255,255,255}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{0,60},{24,-42}}),Rectangle(lineColor={0,0,255}, extent={{-20,80},{20,40}}, fillColor={255,255,255}, fillPattern=FillPattern.Forward)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-60,100},{-60,-100},{60,-100},{60,100},{-60,100}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Rectangle(lineColor={0,0,255}, extent={{-20,100},{20,20}}, fillPattern=FillPattern.Solid, fillColor={255,255,255}),Ellipse(lineColor={0,0,255}, extent={{-22,-16},{30,-66}}, fillColor={255,255,255}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{0,60},{24,-42}}),Rectangle(lineColor={0,0,255}, extent={{-20,80},{20,40}}, fillColor={255,255,255}, fillPattern=FillPattern.Forward)}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Benoît Bride</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-70.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-70.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=70.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=70.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ps props annotation(Placement(transformation(x=-70.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Pe=C1.P;
  Ps=C2.P;
  deltaP=Pe - Ps;
  C1.Q=C2.Q;
  Q=C1.Q;
  0=C1.h - C1.h_vol;
  xm=(proe.x + pros.x)/2.0;
  Q=ThermoSysPro.Functions.Interpolation(deltaP, caract[:,1], caract[:,2]);
  C2.h - C1.h=xm*eta_is*(His - C1.h);
  W=Q*eta_stato*(C1.h - C2.h)*(1 - W_frot/100);
  proe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pe, C1.h, mode_e);
  Te=proe.T;
  pros=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ps, C2.h, mode_s);
  Ts=pros.T;
  props=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ps(Ps, proe.s, mode_s);
  His=props.h;
end SteamEngine;
