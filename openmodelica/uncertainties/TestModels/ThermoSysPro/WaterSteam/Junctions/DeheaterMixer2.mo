within ThermoSysPro.WaterSteam.Junctions;
model DeheaterMixer2
  parameter ThermoSysPro.Units.AbsoluteTemperature Tmax=700 "Maximum fluid temperature";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure P(start=5000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature T(start=600) "Fluid temperature";
  ThermoSysPro.Units.SpecificEnthalpy hmax(start=1000000.0) "Maximum fluid specific enthalpy";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-100,80},{-100,40},{-20,40},{-20,-100},{20,-100},{20,40},{100,40},{100,80},{-100,80}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-16,72},{24,32}}, fillColor={0,0,255}, textString="D")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-100,80},{-100,40},{-20,40},{-20,-100},{20,-100},{20,40},{100,40},{100,80},{-100,80}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-16,72},{24,32}}, fillColor={0,0,255}, textString="D")}), Documentation(info="<html>
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
  Connectors.FluidInlet Ce_mix annotation(Placement(transformation(x=1.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=1.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs annotation(Placement(transformation(x=100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce annotation(Placement(transformation(x=-100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation(Placement(transformation(x=-90.0, y=92.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  P=Ce.P;
  P=Ce_mix.P;
  P=Cs.P;
  Ce.h_vol=h;
  Cs.h_vol=h;
  Ce_mix.h_vol=h;
  0=Ce.Q + Ce_mix.Q - Cs.Q;
  0=Ce.Q*Ce.h + Ce_mix.Q*Ce_mix.h - Cs.Q*Cs.h;
  if T <= Tmax or hmax < Ce_mix.h then
    Ce_mix.Q=0;
  else
    h=hmax;
  end if;
  pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, 1);
  T=pro.T;
  hmax=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(P, Tmax, mode);
end DeheaterMixer2;
