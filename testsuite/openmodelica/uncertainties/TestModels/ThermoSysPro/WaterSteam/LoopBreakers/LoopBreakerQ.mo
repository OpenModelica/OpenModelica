within ThermoSysPro.WaterSteam.LoopBreakers;
model LoopBreakerQ "Mass flow loop breaker for the water/steam connector"
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{0,100},{100,0},{0,-100},{-100,0},{0,100}}, fillPattern=FillPattern.Solid, lineColor={127,0,255}, fillColor={255,255,0}),Line(points={{0,100},{0,-100}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-40,38},{40,-42}}, fillColor={0,0,255}, textString="Q")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{0,100},{100,0},{0,-100},{-100,0},{0,100}}, fillPattern=FillPattern.Solid, lineColor={127,0,255}, fillColor={255,255,0}),Line(points={{0,100},{0,-100}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillColor={0,0,255}, textString="Q")}), Documentation(info="<html>
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
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  C1.P=C2.P;
  C1.h=C2.h;
  0=if C1.Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
end LoopBreakerQ;
