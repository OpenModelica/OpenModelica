within ThermoSysPro.InstrumentationAndControl.Blocks.Sources;
block Random
  parameter Integer seed=1 "Source du générateur aléatoire";
  parameter Real SampleOffset=0 "Instant de départ de l'échantillonnage (s)";
  parameter Real SampleInterval=0.01 "Période d'échantillonnage (s)";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Polygon(points={{90,-70},{68,-62},{68,-78},{90,-70}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-89,90},{-36,72}}, textString="y", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{70,-80},{94,-100}}, textString="temps", fillColor={160,160,160}),Line(points={{-60,-20},{-40,20},{-20,-40},{0,-60},{20,0},{40,40},{60,0}}, color={0,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,-70},{82,-70}}, color={192,192,192}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{-60,-20},{-40,20},{-20,-40},{0,-60},{20,0},{40,40},{60,0}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Version 1.6</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  when initial() then
    Commun.srand(seed);
  end when;
  when sample(SampleOffset, SampleInterval) then
    y.signal=Commun.fmod(Commun.rand()/32768*10, 1);
  end when;
end Random;
