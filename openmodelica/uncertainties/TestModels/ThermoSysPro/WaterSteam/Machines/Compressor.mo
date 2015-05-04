within ThermoSysPro.WaterSteam.Machines;
model Compressor "Heat pump compressor "
  parameter Real pi=10.0 "Compression factor (Ps/Pe)";
  parameter Real eta=0.85 "Isentropic efficiency";
  parameter Modelica.SIunits.Power W_fric=0.0 "Power losses due to hydrodynamic friction (percent)";
  Modelica.SIunits.Power W "Mechanical power delivered to the compressor";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  ThermoSysPro.Units.SpecificEnthalpy His "Fluid specific enthalpy after isentropic compression";
  ThermoSysPro.Units.AbsolutePressure Pe(start=1000000.0) "Inlet pressure";
  ThermoSysPro.Units.AbsolutePressure Ps(start=1000000.0) "Outlet pressure";
  ThermoSysPro.Units.AbsoluteTemperature Te "Inlet temperature";
  ThermoSysPro.Units.AbsoluteTemperature Ts "Outlet temperature";
  Real xm(start=1.0) "Average vapor mass fraction";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Line(points={{-60,80},{60,20},{60,-20},{-60,-80}}, color={0,0,255})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Line(points={{-60,80},{60,20},{60,-20},{-60,-80}}, color={0,0,255})}), Documentation(info="<html>
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
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proe annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pros annotation(Placement(transformation(x=90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ps props annotation(Placement(transformation(x=-90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  C1.Q=C2.Q;
  Pe=C1.P;
  Ps=C2.P;
  Q=C1.Q;
  0=C1.h - C1.h_vol;
  W=Q*(C2.h - C1.h)/(1 - W_fric/100);
  pi=Ps/Pe;
  xm=(proe.x + pros.x)/2.0;
  His - C1.h=xm*eta*(C2.h - C1.h);
  proe=ThermoSysPro.Properties.Fluid.Ph(Pe, C1.h, 0, 2);
  Te=proe.T;
  pros=ThermoSysPro.Properties.Fluid.Ph(Ps, C2.h, 0, 2);
  Ts=pros.T;
  props=ThermoSysPro.Properties.Fluid.Ps(Ps, proe.s, 0, 2);
  His=props.h;
end Compressor;
