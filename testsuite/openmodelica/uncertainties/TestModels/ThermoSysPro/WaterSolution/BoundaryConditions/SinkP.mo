within ThermoSysPro.WaterSolution.BoundaryConditions;
model SinkP "Pressure sink"
  parameter ThermoSysPro.Units.AbsolutePressure P0=300000 "Source pressure";
  parameter ThermoSysPro.Units.AbsoluteTemperature T0=290 "Source temperature";
  parameter Real Xh2o0=0.05 "Source water mass fraction";
  ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  ThermoSysPro.Units.SpecificEnthalpy Xh2o "Water mass fraction";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-90,0},{-40,0},{-58,10}}),Line(color={0,0,255}, points={{-40,0},{-58,-10}}),Text(lineColor={0,0,255}, extent={{40,28},{58,8}}, textString="P"),Text(lineColor={0,0,255}, extent={{-28,60},{-10,40}}, textString="T"),Text(lineColor={0,0,255}, extent={{-28,-40},{-10,-60}}, textString="Xh2o"),Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={160,160,160}),Polygon(lineColor={0,0,255}, points={{-40,40},{-40,-40},{40,-40},{-40,40}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, lineThickness=1.0, fillColor={223,159,159}),Text(lineColor={0,0,255}, extent={{-94,26},{98,-30}}, textString="P")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-90,0},{-40,0},{-58,10}}),Line(color={0,0,255}, points={{-40,0},{-58,-10}}),Text(lineColor={0,0,255}, extent={{-28,60},{-10,40}}, textString="T"),Text(lineColor={0,0,255}, extent={{40,28},{58,8}}, textString="P"),Text(lineColor={0,0,255}, extent={{-28,-40},{-10,-60}}, textString="Xh2o"),Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={160,160,160}),Polygon(lineColor={0,0,255}, points={{-40,40},{-40,-40},{40,-40},{-40,40}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, lineThickness=1.0, fillColor={223,159,159}),Text(lineColor={0,0,255}, extent={{-94,26},{98,-30}}, textString="P")}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Benoît Bride</li>
<li>
    Daniel Bouskela</li>
</html>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure annotation(Placement(transformation(x=50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=180.0), iconTransformation(x=50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=180.0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ITemperature annotation(Placement(transformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IXh2o annotation(Placement(transformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0), iconTransformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0)));
  Connectors.WaterSolutionInlet C annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  C.P=P;
  C.Q=Q;
  C.T=T;
  C.Xh2o=Xh2o;
  if cardinality(IPressure) == 0 then
    IPressure.signal=P0;
  end if;
  P=IPressure.signal;
  if cardinality(ITemperature) == 0 then
    ITemperature.signal=T0;
  end if;
  T=ITemperature.signal;
  if cardinality(IXh2o) == 0 then
    IXh2o.signal=Xh2o0;
  end if;
  Xh2o=IXh2o.signal;
end SinkP;
