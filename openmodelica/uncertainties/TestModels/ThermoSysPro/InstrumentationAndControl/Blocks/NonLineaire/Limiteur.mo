within ThermoSysPro.InstrumentationAndControl.Blocks.NonLineaire;
block Limiteur
  parameter Real maxval=1 "Valeur maximale de la sortie";
  parameter Real minval=-1 "Valeur minimale de la sortie";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{78,60},{40,60},{-40,-60},{-80,-60}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{26,90},{88,68}}, textString="%maxval", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-88,-64},{-26,-86}}, textString="%minval", fillColor={0,0,0}),Line(points={{-86,0},{88,0}}, color={192,192,192}),Polygon(points={{96,0},{86,-5},{86,5},{96,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Polygon(points={{0,84},{-5,74},{5,74},{0,84}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{0,-80},{0,74}}, color={192,192,192})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{26,90},{88,68}}, textString="maxval", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{-88,-64},{-26,-86}}, textString="minval", fillColor={160,160,160}),Line(points={{-86,0},{88,0}}, color={192,192,192}),Polygon(points={{96,0},{86,-5},{86,5},{96,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Polygon(points={{0,84},{-5,74},{5,74},{0,84}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{0,-80},{0,74}}, color={192,192,192}),Line(points={{78,60},{40,60},{-40,-60},{-80,-60}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.NonLinear library</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  assert(maxval > minval, "Limiteur : Le paramètre maxval doit être supérieur au paramètre minval");
  y.signal=if u.signal > maxval then maxval else if u.signal < minval then minval else u.signal;
end Limiteur;
