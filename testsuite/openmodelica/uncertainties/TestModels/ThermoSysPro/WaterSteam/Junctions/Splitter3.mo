within ThermoSysPro.WaterSteam.Junctions;
model Splitter3 "Splitter with three outlets"
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real alpha1 "Extraction coefficient for outlet 1 (<=1)";
  Real alpha2 "Extraction coefficient for outlet 2 (<=1)";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{10,-60},{48,-90}}, textString="3"),Rectangle(lineColor={0,0,255}, extent={{44,-27},{50,-65}}, pattern=LinePattern.None, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{-100,-20},{-100,20},{20,20},{20,100},{60,100},{60,20},{100,20},{100,-20},{60,-20},{60,-100},{20,-100},{20,-20},{-100,-20}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{20,80},{60,40}}, fillColor={0,0,255}, textString="1"),Text(lineColor={0,0,255}, extent={{20,-40},{60,-80}}, fillColor={0,0,255}, textString="2"),Text(lineColor={0,0,255}, extent={{60,20},{100,-20}}, fillColor={0,0,255}, textString="3")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{10,-60},{48,-90}}, textString="3"),Rectangle(lineColor={0,0,255}, extent={{44,-27},{50,-65}}, pattern=LinePattern.None, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Polygon(points={{-100,-20},{-100,20},{20,20},{20,100},{60,100},{60,20},{100,20},{100,-20},{60,-20},{60,-100},{20,-100},{20,-20},{-100,-20}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{20,80},{60,40}}, fillColor={0,0,255}, textString="1"),Text(lineColor={0,0,255}, extent={{20,-40},{60,-80}}, fillColor={0,0,255}, textString="2"),Text(lineColor={0,0,255}, extent={{60,20},{100,-20}}, fillColor={0,0,255}, textString="3")}), Documentation(info="<html>
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
  Connectors.FluidInlet Ce annotation(Placement(transformation(x=-98.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-98.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs3 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs1 annotation(Placement(transformation(x=40.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs2 annotation(Placement(transformation(x=40.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.InputReal Ialpha1 "Extraction coefficient for outlet 1 (<=1)" annotation(Placement(transformation(x=10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.InputReal Ialpha2 "Extraction coefficient for outlet 2 (<=1)" annotation(Placement(transformation(x=10.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=10.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation(Placement(transformation(x=70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.OutputReal Oalpha2 annotation(Placement(transformation(x=70.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=70.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(Ialpha1) == 0 then
    Ialpha1.signal=1;
  end if;
  if cardinality(Ialpha2) == 0 then
    Ialpha2.signal=1;
  end if;
  P=Ce.P;
  P=Cs1.P;
  P=Cs2.P;
  P=Cs3.P;
  Ce.h_vol=h;
  Cs1.h_vol=h;
  Cs2.h_vol=h;
  Cs3.h_vol=h;
  0=Ce.Q - Cs1.Q - Cs2.Q - Cs3.Q;
  0=Ce.Q*Ce.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h - Cs3.Q*Cs3.h;
  if cardinality(Ialpha1) <> 0 then
    Cs1.Q=Ialpha1.signal*Ce.Q;
  end if;
  if cardinality(Ialpha2) <> 0 then
    Cs2.Q=Ialpha2.signal*Ce.Q;
  end if;
  alpha1=Cs1.Q/Ce.Q;
  Oalpha1.signal=alpha1;
  alpha2=Cs2.Q/Ce.Q;
  Oalpha2.signal=alpha2;
  pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);
  T=pro.T;
end Splitter3;
