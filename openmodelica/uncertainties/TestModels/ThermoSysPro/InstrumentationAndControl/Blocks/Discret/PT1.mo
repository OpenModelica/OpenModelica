within ThermoSysPro.InstrumentationAndControl.Blocks.Discret;
block PT1
  parameter Real k=1 "Gain";
  parameter Real Ti=1 "Constante de temps (s)";
  parameter Real initialCond=0 "Condition initiale";
  parameter Real SampleOffset=0 "Instant de départ de l'échantillonnage (s)";
  parameter Real SampleInterval=0.01 "Période d'échantillonnage (s)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Real x(start=initialCond);
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,100},{102,-100}}, fillPattern=FillPattern.Solid, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{-80,78},{-80,-90}}, color={128,128,128}),Line(points={{-90,-80},{82,-80}}, color={128,128,128}),Polygon(points={{90,-80},{68,-72},{68,-88},{90,-80}}, lineColor={0,0,0}, fillColor={128,128,128}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-80,-80},{-70,-45.11},{-60,-19.58},{-50,-0.9087},{-40,12.75},{-30,22.75},{-20,30.06},{-10,35.41},{0,39.33},{10,42.19},{20,44.29},{30,45.82},{40,46.94},{50,47.76},{60,48.36},{70,48.8},{80,49.12}}),Text(lineColor={0,0,255}, extent={{-64,82},{-4,22}}, textString="PT1", fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-38,10},{52,-30}}, textString="K=%k", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-36,-34},{54,-74}}, textString="Ti=%Ti", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-64,82},{-4,22}}, textString="PT1", fillColor={128,128,128}),Polygon(points={{-80,94},{-88,72},{-72,72},{-80,94}}, lineColor={192,192,192}, fillColor={128,128,128}, fillPattern=FillPattern.Solid)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-60,52},{60,6}}, textString="k", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-60,0},{60,-60}}, textString="T s + 1", fillColor={0,0,0}),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{62,0},{102,0}}),Line(points={{-50,0},{50,0}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
algorithm
  when sample(SampleOffset, SampleInterval) then
      x:=(1 - SampleInterval/Ti)*pre(x) + SampleInterval/Ti*pre(u.signal);
    y.signal:=k*x;
  end when;
end PT1;
