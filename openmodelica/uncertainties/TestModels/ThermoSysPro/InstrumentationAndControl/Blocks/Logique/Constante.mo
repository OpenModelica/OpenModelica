within ThermoSysPro.InstrumentationAndControl.Blocks.Logique;
block Constante
  parameter Boolean K=true;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-80,0},{80,0}}, color={0,0,0}, thickness=0.5),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-93,90},{-40,72}}, textString="y", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{70,-80},{94,-100}}, textString="temps", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{-101,8},{-81,-12}}, textString="K", fillColor={160,160,160})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,102}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-154,-14},{146,26}}, textString="%K", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name")}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputLogical yL annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
algorithm
  yL.signal:=K;
end Constante;
