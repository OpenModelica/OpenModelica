within ThermoSysPro.InstrumentationAndControl.Blocks.Discret;
block Pre
  parameter Real Gain=1 "Gain";
  parameter Real initialCond=0 "Condition initiale";
  parameter Real SampleOffset=0 "Instant de départ de l'échantillonnage (s)";
  parameter Real SampleInterval=0.01 "Période d'échantillonnage (s)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Real x(start=initialCond);
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={192,192,192}),Line(points={{-60,0},{60,0}}, color={0,0,0}, thickness=0.5),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Text(lineColor={0,0,255}, extent={{-55,55},{55,5}}, textString="1", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-55,-5},{55,-55}}, textString="z", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-60,60},{60,-60}}, lineColor={0,0,255}),Line(points={{-100,0},{-60,0}}, color={0,0,255}),Line(points={{60,0},{100,0}}, color={0,0,255}),Line(points={{40,0},{-40,0}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-55,55},{55,5}}, textString="1", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-55,-5},{55,-55}}, textString="z", fillColor={0,0,0})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
algorithm
  when sample(SampleOffset, SampleInterval) then
      x:=u.signal;
  end when;
  when sample(SampleOffset, SampleInterval) then
      y.signal:=Gain*pre(x);
  end when;
end Pre;
