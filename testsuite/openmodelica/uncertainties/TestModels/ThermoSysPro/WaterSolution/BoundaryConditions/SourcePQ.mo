within ThermoSysPro.WaterSolution.BoundaryConditions;
model SourcePQ "Pressure and mass flow source"
  parameter ThermoSysPro.Units.AbsolutePressure P=100000.0 "Source presure";
  parameter Modelica.SIunits.MassFlowRate Q=10 "Mass flow rate";
  parameter ThermoSysPro.Units.AbsoluteTemperature T=300 "Source temperature";
  parameter Real Xh2o=0.05 "h2o mass fraction";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={160,160,160}),Line(color={0,0,255}, points={{40,0},{90,0},{72,10}}),Line(color={0,0,255}, points={{90,0},{72,-10}}),Polygon(points={{-40,-40},{-40,40},{40,-40},{-40,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={160,160,160}),Line(color={0,0,255}, points={{40,0},{90,0},{72,10}}),Line(color={0,0,255}, points={{90,0},{72,-10}}),Polygon(points={{-40,-40},{-40,40},{40,-40},{-40,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159})}), Documentation(info="<html>
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
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet Cs annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Cs.Xh2o=Xh2o;
  Cs.T=T;
  Cs.Q=Q;
  Cs.P=P;
end SourcePQ;
