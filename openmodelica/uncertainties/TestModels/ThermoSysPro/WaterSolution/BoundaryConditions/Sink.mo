within ThermoSysPro.WaterSolution.BoundaryConditions;
model Sink
  ThermoSysPro.Units.AbsolutePressure P "Sink pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  ThermoSysPro.Units.AbsoluteTemperature T "Sink Temperature";
  Real Xh2o "h2o mas fraction";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={160,160,160}),Polygon(lineColor={0,0,255}, points={{-40,40},{-40,-40},{40,-40},{-40,40}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, lineThickness=1.0, fillColor={223,159,159}),Line(color={0,0,255}, points={{-90,0},{-40,0},{-58,10}}),Line(color={0,0,255}, points={{-40,0},{-58,-10}})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={160,160,160}),Line(color={0,0,255}, points={{-90,0},{-40,0},{-58,10}}),Line(color={0,0,255}, points={{-40,0},{-58,-10}}),Polygon(lineColor={0,0,255}, points={{-40,40},{-40,-40},{40,-40},{-40,40}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, lineThickness=1.0, fillColor={223,159,159})}), Documentation(info="<html>
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
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionInlet Ce annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Ce.Xh2o=Xh2o;
  Ce.T=T;
  Ce.Q=Q;
  Ce.P=P;
end Sink;
