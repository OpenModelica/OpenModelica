within ThermoSysPro.FlueGases.BoundaryConditions;
model SinkPQ "Flue gas sink with fixed pressure and mass flow rate"
  parameter ThermoSysPro.Units.AbsolutePressure P0=100000 "Sink pressure";
  parameter Modelica.SIunits.MassFlowRate Q0=100 "Sink mass flow rate";
  ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  Real Xco2 "CO2 mass fraction";
  Real Xh2o "H2O mass fraction";
  Real Xo2 "O2 mass fraction";
  Real Xso2 "SO2 mass fraction";
  Real Xn2 "N2 mass fraction";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Text(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, textString="PQ"),Line(color={0,0,255}, points={{-90,0},{-40,0},{-58,10}}),Line(color={0,0,255}, points={{-40,0},{-58,-10}}),Text(lineColor={0,0,255}, extent={{40,28},{64,6}}, fillColor={0,0,255}, textString="P"),Text(lineColor={0,0,255}, extent={{-40,60},{-6,40}}, fillColor={0,0,255}, textString="Q")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Text(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, textString="PQ"),Line(color={0,0,255}, points={{-90,0},{-40,0},{-58,10}}),Line(color={0,0,255}, points={{-40,0},{-58,-10}}),Text(lineColor={0,0,255}, extent={{40,28},{64,6}}, fillColor={0,0,255}, textString="P"),Text(lineColor={0,0,255}, extent={{-40,60},{-6,40}}, fillColor={0,0,255}, textString="Q")}), Documentation(info="<html>
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
</ul>
</html>
"));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet C annotation(Placement(transformation(x=-98.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-98.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure annotation(Placement(transformation(x=50.0, y=0.0, scale=0.1, aspectRatio=0.9, flipHorizontal=true, flipVertical=false), iconTransformation(x=50.0, y=0.0, scale=0.1, aspectRatio=0.9, flipHorizontal=true, flipVertical=false)));
  InstrumentationAndControl.Connectors.InputReal IMassFlow annotation(Placement(transformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
equation
  C.P=P;
  C.Q=Q;
  C.T=T;
  C.Xco2=Xco2;
  C.Xh2o=Xh2o;
  C.Xo2=Xo2;
  C.Xso2=Xso2;
  Xn2=1 - Xco2 - Xh2o - Xo2 - Xso2;
  if cardinality(IPressure) == 0 then
    IPressure.signal=P0;
  end if;
  P=IPressure.signal;
  if cardinality(IMassFlow) == 0 then
    IMassFlow.signal=Q0;
  end if;
  Q=IMassFlow.signal;
end SinkPQ;
