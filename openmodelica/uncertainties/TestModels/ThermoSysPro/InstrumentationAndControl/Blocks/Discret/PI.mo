within ThermoSysPro.InstrumentationAndControl.Blocks.Discret;
block PI
  parameter Real k=1 "Gain";
  parameter Real Ti=1 "Constante de temps";
  parameter Real initialCond=0 "Condition initiale";
  parameter Real SampleOffset=0 "Instant de départ de l'échantillonnage (s)";
  parameter Real SampleInterval=0.01 "Période d'échantillonnage (s)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Real x(start=initialCond);
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={192,192,192}),Line(points={{-74,64},{-74,-80}}, color={0,0,0}),Line(points={{-74,-80},{70,-80}}, color={0,0,0}),Polygon(points={{92,-80},{70,-72},{70,-88},{92,-80}}, lineColor={192,192,192}, fillColor={160,160,160}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-74,-68},{-74,2},{66,58}}, thickness=0.25),Text(lineColor={0,0,255}, extent={{-32,70},{0,42}}, textString="PI", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{-154,142},{146,102}}, textString="%name"),Text(lineColor={0,0,255}, extent={{-38,10},{52,-30}}, textString="K=%k", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-36,-34},{54,-74}}, textString="Ti=%Ti", fillColor={0,0,0}),Polygon(points={{-74,86},{-82,64},{-66,64},{-74,86}}, lineColor={192,192,192}, fillColor={128,128,128}, fillPattern=FillPattern.Solid)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{62,0},{100,0}}),Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-68,24},{-24,-18}}, textString="k", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-32,48},{60,0}}, textString="T s + 1", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-30,-8},{52,-40}}, textString="T s", fillColor={0,0,0}),Line(points={{-24,0},{54,0}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
algorithm
  when sample(SampleOffset, SampleInterval) then
      x:=pre(x) + SampleInterval/Ti*pre(u.signal);
    y.signal:=k*(x + u.signal);
  end when;
end PI;
