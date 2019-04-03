within ThermoSysPro.FlueGases.Junctions;
model Mixer2 "Flue gases mixer with two inlets"
  Real alpha1 "Extraction coefficient for inlet 1 (<=1)";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=100000) "Fluid specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  Real Xco2 "CO2 mass fraction";
  Real Xh2o "H20 mass fraction";
  Real Xo2 "O2 mass fraction";
  Real Xso2 "SO2 mass fraction";
  Real Xn2 "N2 mass fraction";
  ThermoSysPro.Units.SpecificEnthalpy he1(start=100000) "Fluid specific enthalpy at inlet #1";
  ThermoSysPro.Units.SpecificEnthalpy he2(start=100000) "Fluid specific enthalpy at inlet #2";
  ThermoSysPro.Units.SpecificEnthalpy hs(start=100000) "Fluid specific enthalpy at the outlet";
  Connectors.FlueGasesInlet Ce2 annotation(Placement(transformation(x=-40.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-40.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesOutlet Cs annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesInlet Ce1 annotation(Placement(transformation(x=-40.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-40.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.InputReal Ialpha1 "Extraction coefficient for inlet 1 (<=1)" annotation(Placement(transformation(x=-70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-70.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.OutputReal Oalpha1 annotation(Placement(transformation(x=-10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-10.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(Ialpha1) == 0 then
    Ialpha1.signal=1;
  end if;
  P=Ce1.P;
  P=Ce2.P;
  P=Cs.P;
  Cs.T=T;
  Cs.Xco2=Xco2;
  Cs.Xh2o=Xh2o;
  Cs.Xo2=Xo2;
  Cs.Xso2=Xso2;
  Xn2=1 - Xco2 - Xh2o - Xo2 - Xso2;
  0=Ce1.Q + Ce2.Q - Cs.Q;
  0=Ce1.Q*he1 + Ce2.Q*he2 - Cs.Q*hs;
  0=Ce1.Xco2*Ce1.Q + Ce2.Xco2*Ce2.Q - Cs.Xco2*Cs.Q;
  0=Ce1.Xh2o*Ce1.Q + Ce2.Xh2o*Ce2.Q - Cs.Xh2o*Cs.Q;
  0=Ce1.Xo2*Ce1.Q + Ce2.Xo2*Ce2.Q - Cs.Xo2*Cs.Q;
  0=Ce1.Xso2*Ce1.Q + Ce2.Xso2*Ce2.Q - Cs.Xso2*Cs.Q;
  if cardinality(Ialpha1) <> 0 then
    Ce1.Q=Ialpha1.signal*Cs.Q;
  end if;
  alpha1=Ce1.Q/Cs.Q;
  Oalpha1.signal=alpha1;
  he1=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, Ce1.T, Ce1.Xco2, Ce1.Xh2o, Ce1.Xo2, Ce1.Xso2);
  he2=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, Ce2.T, Ce2.Xco2, Ce2.Xh2o, Ce2.Xo2, Ce2.Xso2);
  hs=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, Cs.T, Cs.Xco2, Cs.Xh2o, Cs.Xo2, Cs.Xso2);
  h=ThermoSysPro.Properties.FlueGases.FlueGases_h(P, T, Xco2, Xh2o, Xo2, Xso2);
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,-100},{-20,-100},{-20,-20},{100,-20},{100,20},{-20,20},{-20,100},{-60,100},{-60,-100}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Text(lineColor={0,0,255}, extent={{-60,80},{-20,40}}, textString="1"),Text(lineColor={0,0,255}, extent={{-60,-40},{-20,-80}}, textString="2")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,-100},{-20,-100},{-20,-20},{100,-20},{100,20},{-20,20},{-20,100},{-60,100},{-60,-100}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Text(lineColor={0,0,255}, extent={{-60,80},{-20,40}}, textString="1"),Text(lineColor={0,0,255}, extent={{-60,-40},{-20,-80}}, textString="2")}), Documentation(info="<html>
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
end Mixer2;
