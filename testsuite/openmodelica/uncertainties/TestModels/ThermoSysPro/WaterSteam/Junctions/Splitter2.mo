within ThermoSysPro.WaterSteam.Junctions;
model Splitter2 "Splitter with two outlets"
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real alpha1 "Extraction coefficient for outlet 1 (<=1)";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{20,20},{20,100},{60,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{20,80},{60,40}}, textString="1"),Text(lineColor={0,0,255}, extent={{20,-40},{60,-80}}, textString="2")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{20,20},{20,100},{60,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{20,80},{60,40}}, textString="1"),Text(lineColor={0,0,255}, extent={{20,-40},{60,-80}}, textString="2")}), Documentation(info="<html>
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
"), DymolaStoredErrors);
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce annotation(Placement(visible=true, transformation(origin={-100.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-98.8443,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs1 annotation(Placement(visible=true, transformation(origin={40.0,100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={39.4379,99.8428}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs2 annotation(Placement(visible=true, transformation(origin={40.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={39.4379,-100.342}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  InstrumentationAndControl.Connectors.InputReal Ialpha1 "Extraction coefficient for outlet 1 (<=1)" annotation(Placement(transformation(x=10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation(Placement(transformation(x=70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(Ialpha1) == 0 then
    Ialpha1.signal=1;
  end if;
  P=Ce.P;
  P=Cs1.P;
  P=Cs2.P;
  Ce.h_vol=h;
  Cs1.h_vol=h;
  Cs2.h_vol=h;
  0=Ce.Q - Cs1.Q - Cs2.Q;
  0=Ce.Q*Ce.h - Cs1.Q*Cs1.h - Cs2.Q*Cs2.h;
  if cardinality(Ialpha1) <> 0 then
    Cs1.Q=Ialpha1.signal*Ce.Q;
  end if;
  alpha1=Cs1.Q/Ce.Q;
  Oalpha1.signal=alpha1;
  pro=ThermoSysPro.Properties.Fluid.Ph(P, h, mode, fluid);
  T=pro.T;
end Splitter2;
