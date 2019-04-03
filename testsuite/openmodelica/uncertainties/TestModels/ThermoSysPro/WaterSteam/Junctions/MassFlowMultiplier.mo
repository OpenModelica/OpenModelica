within ThermoSysPro.WaterSteam.Junctions;
model MassFlowMultiplier "Mass flow multipliier"
  parameter Real alpha=2 "Flow multiplier";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-100,60},{-100,-60},{90,0},{-100,60}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{-60,24},{-20,-16}}, fillColor={0,0,255}, textString="%alpha")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-100,60},{-100,-60},{90,0},{-100,60}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{-60,24},{-20,-16}}, fillColor={0,0,255}, textString="%alpha")}), Documentation(info="<html>
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
  Connectors.FluidInlet Ce annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  P=Ce.P;
  P=Cs.P;
  Ce.h_vol=h;
  Cs.h_vol=h;
  0=alpha*Ce.Q - Cs.Q;
  0=alpha*Ce.Q*Ce.h - Cs.Q*Cs.h;
  pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);
  T=pro.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=pro.d;
  end if;
end MassFlowMultiplier;
