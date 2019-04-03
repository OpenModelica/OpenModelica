within ThermoSysPro.InstrumentationAndControl.Blocks.NonLineaire;
block BandeMorte
  parameter Real uMax=1 "Limite supérieure de la bande morte";
  parameter Real uMin=-uMax "Limite inférieure de la bande morte";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{0,-90},{0,68}}, color={192,192,192}),Polygon(points={{0,90},{-8,68},{8,68},{0,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,0},{68,0}}, color={192,192,192}),Polygon(points={{90,0},{68,-8},{68,8},{90,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,-60},{-20,0},{20,0},{80,60}}, color={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{0,-60},{0,50}}, color={192,192,192}),Polygon(points={{0,60},{-5,50},{5,50},{0,60}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-76,0},{74,0}}, color={192,192,192}),Polygon(points={{84,0},{74,-5},{74,5},{84,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-81,-40},{-38,0},{40,0},{80,40}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{62,-5},{88,-23}}, textString="u", fillColor={128,128,128}),Text(lineColor={0,0,255}, extent={{-34,68},{-3,46}}, textString="y", fillColor={128,128,128}),Text(lineColor={0,0,255}, extent={{-51,1},{-28,19}}, textString="uMin", fillColor={128,128,128}),Text(lineColor={0,0,255}, extent={{27,21},{52,5}}, textString="uMax", fillColor={128,128,128})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.NonLinear library</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  y.signal=if u.signal > uMax then u.signal - uMax else if u.signal < uMin then u.signal - uMin else 0;
end BandeMorte;
