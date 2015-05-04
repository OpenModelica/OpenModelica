within ThermoSysPro.InstrumentationAndControl.Blocks.Continu;
block PT2
  parameter Real k=1 "Gain";
  parameter Real w=1 "Fréquence angulaire";
  parameter Real D=1 "Amortissement";
  parameter Boolean permanent=false "Calcul du permanent";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Real x(start=0);
  Real xd(start=0);
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-60,52},{60,6}}, textString="k", fillColor={0,0,0}),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{62,0},{102,0}}),Line(points={{-50,0},{50,0}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-60,0},{-32,-28}}, textString="s", fillColor={0,0,0}),Line(points={{-54,-28},{-38,-28}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-52,-34},{-36,-56}}, textString="w", fillColor={0,0,0}),Line(points={{-40,-6},{-34,-18},{-34,-38},{-38,-54}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-34,0},{-22,-18}}, textString="2", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-34,-14},{6,-44}}, textString="+2D", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{2,0},{30,-28}}, textString="s", fillColor={0,0,0}),Line(points={{8,-28},{24,-28}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{10,-34},{26,-56}}, textString="w", fillColor={0,0,0}),Line(points={{12,-6},{6,-16},{6,-36},{10,-54}}, color={0,0,0}),Line(points={{22,-6},{28,-18},{28,-38},{24,-54}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{30,-6},{58,-50}}, textString="+1", fillColor={0,0,0}),Line(points={{-50,-6},{-56,-16},{-56,-36},{-52,-54}}, color={0,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(points={{-80,78},{-80,-90}}, color={192,192,192}),Line(points={{-90,-80},{82,-80}}, color={192,192,192}),Polygon(points={{90,-80},{68,-72},{68,-88},{90,-80}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-80,-80},{-72,-68.53},{-64,-39.5},{-56,-2.522},{-48,32.75},{-40,58.8},{-32,71.51},{-24,70.49},{-16,58.45},{-8,40.06},{0,20.55},{8,4.459},{16,-5.271},{24,-7.629},{32,-3.428},{40,5.21},{48,15.56},{56,25.03},{64,31.66},{72,34.5},{80,33.61}}),Text(lineColor={0,0,255}, extent={{-2,90},{58,30}}, textString="PT2", fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-150,-150},{150,-110}}, textString="w=%w", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-64,4},{26,-36}}, textString="K=%k", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-62,-40},{28,-80}}, textString="D=%D", fillColor={0,0,0}),Polygon(points={{-80,94},{-88,72},{-72,72},{-80,94}}, lineColor={192,192,192}, fillColor={192,192,192}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Continuous library</b></p>
</HTML>
"));
initial equation
  if permanent then
    der(x)=0;
    der(xd)=0;
  end if;
equation
  der(x)=xd;
  der(xd)=w*(w*(u.signal - x) - 2*D*xd);
  y.signal=k*x;
end PT2;
