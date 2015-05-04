within ThermoSysPro.WaterSolution.LoopBreakers;
model LoopBreakerP "Pressure loop breaker for the water solution connector"
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{0,100},{100,0},{0,-100},{-100,0},{0,100}}, fillPattern=FillPattern.Solid, lineColor={127,0,255}, fillColor={223,159,159}),Line(points={{0,100},{0,-100}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-42,38},{38,-42}}, fillColor={0,0,255}, textString="P")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{0,100},{100,0},{0,-100},{-100,0},{0,100}}, fillPattern=FillPattern.Solid, lineColor={127,0,255}, fillColor={223,159,159}),Line(points={{0,100},{0,-100}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-40,38},{40,-42}}, fillColor={0,0,255}, textString="P")}), Documentation(info="<html>
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
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet Cs annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Cs.Q=Ce.Q;
  Cs.T=Ce.T;
  Cs.Xh2o=Ce.Xh2o;
end LoopBreakerP;
