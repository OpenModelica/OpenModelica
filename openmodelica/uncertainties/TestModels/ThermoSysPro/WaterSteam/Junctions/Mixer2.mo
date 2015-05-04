within ThermoSysPro.WaterSteam.Junctions;
model Mixer2 "Mixer with two inlets"
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real alpha1 "Extraction coefficient for inlet 1 (<=1)";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,-100},{-20,-100},{-20,-20},{100,-20},{100,20},{-20,20},{-20,100},{-60,100},{-60,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{-60,80},{-20,40}}, textString="1"),Text(lineColor={0,0,255}, extent={{-60,-40},{-20,-80}}, textString="2")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,-100},{-20,-100},{-20,-20},{100,-20},{100,20},{-20,20},{-20,100},{-60,100},{-60,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{-60,80},{-20,40}}, textString="1"),Text(lineColor={0,0,255}, extent={{-60,-40},{-20,-80}}, textString="2")}), Documentation(info="<html>
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
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce2 annotation(Placement(visible=true, transformation(origin={-40.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-39.9371,-99.3436}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs annotation(Placement(visible=true, transformation(origin={100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={98.8443,-0.9984}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce1 annotation(Placement(visible=true, transformation(origin={-40.0,97.8459}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-39.9371,97.8459}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  InstrumentationAndControl.Connectors.InputReal Ialpha1 "Extraction coefficient for inlet 1 (<=1)" annotation(Placement(transformation(x=-70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation(Placement(transformation(x=-10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(Ialpha1) == 0 then
    Ialpha1.signal=1;
  end if;
  P=Ce1.P;
  P=Ce2.P;
  P=Cs.P;
  Ce1.h_vol=h;
  Ce2.h_vol=h;
  Cs.h_vol=h;
  0=Ce1.Q + Ce2.Q - Cs.Q;
  0=Ce1.Q*Ce1.h + Ce2.Q*Ce2.h - Cs.Q*Cs.h;
  if cardinality(Ialpha1) <> 0 then
    Ce1.Q=Ialpha1.signal*Cs.Q;
  end if;
  alpha1=Ce1.Q/Cs.Q;
  Oalpha1.signal=alpha1;
  pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);
  T=pro.T;
end Mixer2;
