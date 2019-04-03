within ThermoSysPro.Combustion.Sensors;
model FuelMassFlowSensor "Fuel mass flow rate sensor"
  Modelica.SIunits.MassFlowRate Q(start=20) "Mass flow rate";
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Mesure annotation(Placement(transformation(x=0.0, y=102.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=102.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.Combustion.Connectors.FuelInlet C1 annotation(Placement(transformation(x=-100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Combustion.Connectors.FuelOutlet C2 annotation(Placement(transformation(x=102.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=102.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  C1.Q=C2.Q;
  C1.T=C2.T;
  C1.P=C2.P;
  C1.LHV=C2.LHV;
  C1.cp=C2.cp;
  C1.hum=C2.hum;
  C1.Xc=C2.Xc;
  C1.Xh=C2.Xh;
  C1.Xo=C2.Xo;
  C1.Xn=C2.Xn;
  C1.Xs=C2.Xs;
  C1.Xashes=C2.Xashes;
  C1.VolM=C2.VolM;
  C1.rho=C2.rho;
  Q=C1.Q;
  Mesure.signal=Q;
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{0,-28},{0,-80}}),Line(color={0,0,255}, points={{-98,-80},{102,-80}}),Ellipse(lineColor={0,0,255}, extent={{-60,92},{60,-28}}, fillColor={0,255,0}, fillPattern=FillPattern.CrossDiag),Text(lineColor={0,0,255}, extent={{-60,60},{60,0}}, textString="Q")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{0,-28},{0,-80}}, color={0,0,255}),Line(color={0,0,255}, points={{-98,-80},{102,-80}}),Ellipse(lineColor={0,0,255}, extent={{-60,92},{60,-28}}, fillColor={0,255,0}, fillPattern=FillPattern.CrossDiag),Text(lineColor={0,0,255}, extent={{-60,60},{60,0}}, textString="Q")}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Salimou Gassama</li>
</ul>
</html>
"));
end FuelMassFlowSensor;
