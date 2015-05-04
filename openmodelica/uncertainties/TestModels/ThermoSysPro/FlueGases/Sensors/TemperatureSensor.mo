within ThermoSysPro.FlueGases.Sensors;
model TemperatureSensor "Temperature sensor"
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-60,92},{60,-28}}, fillColor={0,255,0}, fillPattern=FillPattern.Backward),Line(color={0,0,255}, points={{0,-30},{0,-80}}),Line(color={0,0,255}, points={{-98,-80},{102,-80}}),Text(lineColor={0,0,255}, extent={{-60,60},{60,0}}, textString="T")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-60,92},{60,-28}}, fillColor={0,255,0}, fillPattern=FillPattern.Backward),Line(color={0,0,255}, points={{0,-30},{0,-80}}),Line(color={0,0,255}, points={{-98,-80},{102,-80}}),Text(lineColor={0,0,255}, extent={{-60,60},{60,0}}, textString="T")}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Mesure annotation(Placement(transformation(x=0.0, y=102.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=102.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  Connectors.FlueGasesInlet C1 annotation(Placement(transformation(x=-100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesOutlet C2 annotation(Placement(transformation(x=100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  C1.P=C2.P;
  C1.T=C2.T;
  C1.Q=C2.Q;
  C1.Xco2=C2.Xco2;
  C1.Xh2o=C2.Xh2o;
  C1.Xo2=C2.Xo2;
  C1.Xso2=C2.Xso2;
  Mesure.signal=C1.T;
end TemperatureSensor;
