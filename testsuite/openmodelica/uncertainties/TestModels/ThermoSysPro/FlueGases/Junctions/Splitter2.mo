within ThermoSysPro.FlueGases.Junctions;
model Splitter2 "Flue gases splitter with two outlets"
  Real alpha1 "Extraction coefficient for outlet 1 (<=1)";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  Real Xco2 "CO2 mass fraction";
  Real Xh2o "H20 mass fraction";
  Real Xo2 "O2 mass fraction";
  Real Xso2 "SO2 mass fraction";
  Real Xn2 "N2 mass fraction";
  ThermoSysPro.Units.SpecificEnthalpy he(start=100000) "Fluid specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy hs1(start=100000) "Fluid specific enthalpy at outlet #1";
  ThermoSysPro.Units.SpecificEnthalpy hs2(start=100000) "Fluid specific enthalpy at outlet #2";
  Connectors.FlueGasesInlet Ce annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesOutlet Cs1 annotation(Placement(transformation(x=40.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesOutlet Cs2 annotation(Placement(transformation(x=40.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.InputReal Ialpha1 "Extraction coefficient for outlet 1 (<=1)" annotation(Placement(transformation(x=10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation(Placement(transformation(x=70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(Ialpha1) == 0 then
    Ialpha1.signal=1;
  end if;
  P=Ce.P;
  P=Cs1.P;
  P=Cs2.P;
  Cs1.T=T;
  Cs2.T=T;
  Cs1.Xco2=Xco2;
  Cs1.Xh2o=Xh2o;
  Cs1.Xo2=Xo2;
  Cs1.Xso2=Xso2;
  Cs2.Xco2=Xco2;
  Cs2.Xh2o=Xh2o;
  Cs2.Xo2=Xo2;
  Cs2.Xso2=Xso2;
  Xn2=1 - Xco2 - Xh2o - Xo2 - Xso2;
  0=Ce.Q - Cs1.Q - Cs2.Q;
  0=Ce.Q*he - Cs1.Q*hs1 - Cs2.Q*hs2;
  0=Ce.Xco2*Ce.Q - Cs1.Xco2*Cs1.Q - Cs2.Xco2*Cs2.Q;
  0=Ce.Xh2o*Ce.Q - Cs1.Xh2o*Cs1.Q - Cs2.Xh2o*Cs2.Q;
  0=Ce.Xo2*Ce.Q - Cs1.Xo2*Cs1.Q - Cs2.Xo2*Cs2.Q;
  0=Ce.Xso2*Ce.Q - Cs1.Xso2*Cs1.Q - Cs2.Xso2*Cs2.Q;
  if cardinality(Ialpha1) <> 0 then
    Cs1.Q=Ialpha1.signal*Ce.Q;
  end if;
  alpha1=Cs1.Q/Ce.Q;
  Oalpha1.signal=alpha1;
  he=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, Ce.T, Ce.Xco2, Ce.Xh2o, Ce.Xo2, Ce.Xso2);
  hs1=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, Cs1.T, Cs1.Xco2, Cs1.Xh2o, Cs1.Xo2, Cs1.Xso2);
  hs2=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, Cs2.T, Cs2.Xco2, Cs2.Xh2o, Cs2.Xo2, Cs2.Xso2);
  h=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, T, Xco2, Xh2o, Xo2, Xso2);
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{20,20},{20,100},{60,100}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Text(lineColor={0,0,255}, extent={{20,80},{60,40}}, textString="1"),Text(lineColor={0,0,255}, extent={{20,-40},{60,-80}}, textString="2")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{60,100},{60,-100},{20,-100},{20,-20},{-100,-20},{-100,20},{20,20},{20,100},{60,100}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Text(lineColor={0,0,255}, extent={{20,80},{60,40}}, textString="1"),Text(lineColor={0,0,255}, extent={{20,-40},{60,-80}}, textString="2")}), Documentation(info="<html>
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
end Splitter2;
