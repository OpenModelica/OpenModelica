within ThermoSysPro.InstrumentationAndControl.Blocks.Sources;
block Constante
  parameter Real k=1 "Valeur de la sortie";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Line(points={{-80,0},{80,0}}, color={0,0,0}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-89,90},{-36,72}}, textString="y", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{70,-80},{94,-100}}, textString="temps", fillColor={160,160,160})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-80,0},{80,0}}, color={0,0,0}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Text(lineColor={0,0,255}, extent={{-148,14},{152,54}}, textString="%k", fillColor={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Sources librarys</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  y.signal=k;
end Constante;
