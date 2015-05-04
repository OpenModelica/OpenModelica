within ThermoSysPro.WaterSteam.Machines;
model StodolaTurbine "Multistage turbine group using Stodola's ellipse"
  parameter Real Cst=10000000.0 "Stodola's ellipse coefficient";
  parameter Real W_fric=0.0 "Power losses due to hydrodynamic friction (percent)";
  parameter Real eta_stato=1.0 "Efficiency to account for cinetic losses (<= 1) (s.u.)";
  parameter Modelica.SIunits.Area area_nz=1 "Nozzle area";
  parameter Real eta_nz=1.0 "Nozzle efficency (eta_nz < 1 - turbine with nozzle - eta_nz = 1 - turbine without nozzle)";
  parameter Modelica.SIunits.MassFlowRate Qmax=15 "Maximum mass flow through the turbine";
  parameter Real eta_is_nom=0.8 "Nominal isentropic efficiency";
  parameter Real eta_is_min=0.35 "Minimum isentropic efficiency";
  parameter Real a=-1.3889 "x^2 coefficient of the isentropic efficiency characteristics eta_is=f(Q/Qmax)";
  parameter Real b=2.6944 "x coefficient of the isentropic efficiency characteristics eta_is=f(Q/Qmax)";
  parameter Real c=-0.5056 "Constant coefficient of the isentropic efficiency characteristics eta_is=f(Q/Qmax)";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Integer mode_e=0 "IF97 region before expansion. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_s=0 "IF97 region after expansion. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_ps=0 "IF97 region after isentropic expansion. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real eta_is(start=0.85) "Isentropic efficiency";
  Modelica.SIunits.Power W "Mechanical power produced by the turbine";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  ThermoSysPro.Units.SpecificEnthalpy His "Fluid specific enthalpy after isentropic expansion";
  ThermoSysPro.Units.SpecificEnthalpy Hrs "Fluid specific enthalpy after the real expansion";
  ThermoSysPro.Units.AbsolutePressure Pe(start=1000000.0, min=0) "Pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Ps(start=1000000.0, min=0) "Pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Te(min=0) "Temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Ts(min=0) "Temperature at the outlet";
  Modelica.SIunits.Velocity Vs "Fluid velocity at the outlet";
  Modelica.SIunits.Density rhos(start=200) "Fluid density at the outlet";
  Real xm(start=1.0, min=0) "Average vapor mass fraction";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proe annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pros annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,40},{-100,-40},{100,-100},{100,100},{-100,40}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Line(points={{0,-70},{0,-90}}, color={0,0,0}, thickness=0.5)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,40},{-100,-40},{100,-100},{100,100},{-100,40}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Line(points={{0,-70},{0,-90}}, color={0,0,0}, thickness=0.5)}), Documentation(info="<html>
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
"));
  Connectors.FluidInlet Ce annotation(Placement(transformation(x=-101.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-101.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs annotation(Placement(transformation(x=101.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=101.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ps props annotation(Placement(transformation(x=-90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.ElectroMechanics.Connectors.MechanichalTorque M annotation(Placement(transformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=-90.0), iconTransformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=-90.0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal MechPower annotation(Placement(transformation(x=110.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-180.0), iconTransformation(x=110.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-180.0)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pros1 annotation(Placement(transformation(x=-10.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(M) == 0 then
    M.Ctr=0;
    M.w=0;
  else
    M.Ctr*M.w=W;
  end if;
  Pe=Ce.P;
  Ps=Cs.P;
  Ce.Q=Cs.Q;
  Q=Ce.Q;
  0=Ce.h - Ce.h_vol;
  eta_is=if Q < Qmax then max(eta_is_min, a*(Q/Qmax)^2 + b*(Q/Qmax) + c) else eta_is_nom;
  xm=(proe.x + pros1.x)/2.0;
  Q=sqrt((Pe^2 - Ps^2)/(Cst*Te*proe.x));
  Hrs - Ce.h=xm*eta_is*(His - Ce.h);
  Vs=Q/rhos/area_nz;
  Cs.h - Hrs=(1 - eta_nz)*Vs^2/2;
  W=Q*eta_stato*(Ce.h - Cs.h)*(1 - W_fric/100);
  MechPower.signal=W;
  proe=ThermoSysPro.Properties.Fluid.Ph(Pe, Ce.h, mode_e, fluid);
  Te=proe.T;
  pros1=ThermoSysPro.Properties.Fluid.Ph(Ps, Hrs, mode_s, fluid);
  pros=ThermoSysPro.Properties.Fluid.Ph(Ps, Cs.h, mode_s, fluid);
  Ts=pros.T;
  rhos=pros.d;
  props=ThermoSysPro.Properties.Fluid.Ps(Ps, proe.s, mode_ps, fluid);
  His=props.h;
end StodolaTurbine;
