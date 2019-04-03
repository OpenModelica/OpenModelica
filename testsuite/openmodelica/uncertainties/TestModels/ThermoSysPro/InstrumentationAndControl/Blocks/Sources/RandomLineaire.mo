within ThermoSysPro.InstrumentationAndControl.Blocks.Sources;
block RandomLineaire
  parameter Integer seed=1 "Source du générateur aléatoire";
  parameter Real SampleOffset=0 "Instant de départ de l'échantillonnage";
  parameter Real SampleInterval=0.01 "Période d'échantillonnage";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(points={{-80,68},{-80,-80}}, color={192,192,192}),Line(points={{-90,0},{82,0}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Polygon(points={{98,0},{76,8},{76,-8},{98,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-89,90},{-36,72}}, textString="y", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{72,-8},{96,-28}}, textString="temps", fillColor={160,160,160}),Line(points={{-60,-20},{-40,20},{-20,-40},{0,-60},{20,0},{40,40},{60,0}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-88,64},{-58,46}}, fillColor={0,0,255}, textString="1"),Text(lineColor={0,0,255}, extent={{-88,-52},{-58,-70}}, fillColor={0,0,255}, textString="-1")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{-82,66},{-82,-82}}, color={192,192,192}),Line(points={{-92,-2},{80,-2}}, color={192,192,192}),Polygon(points={{-82,88},{-90,66},{-74,66},{-82,88}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Polygon(points={{96,-2},{74,6},{74,-10},{96,-2}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-62,-22},{-42,18},{-22,-42},{-2,-62},{18,-2},{38,38},{58,-2}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-90,62},{-60,44}}, fillColor={0,0,255}, textString="1"),Text(lineColor={0,0,255}, extent={{-90,-54},{-60,-72}}, fillColor={0,0,255}, textString="-1")}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Sources library</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical uL annotation(Placement(transformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
protected
  Real p1;
  Real p2;
  Real t1;
  Real t2;
  discrete Real Interval;
algorithm
  when initial() then
      Commun.srand(seed);
    t1:=0;
    t2:=SampleOffset;
    p1:=0;
    p2:=0;
    Interval:=if uL.signal then SampleInterval else Modelica.Constants.inf;
  end when;
  when change(uL.signal) then
      Interval:=if uL.signal then SampleInterval else Modelica.Constants.inf;
  end when;
  when edge(uL.signal) then
      p2:=0;
    p1:=0;
  end when;
  when sample(SampleOffset, Interval) and uL.signal then
      p1:=p2;
    p2:=2*(Commun.fmod(Commun.rand()/32768*10, 1) - 0.5);
    t1:=time;
    t2:=t2 + SampleInterval;
  end when;
  y.signal:=if uL.signal then p1 + (p2 - p1)/SampleInterval*(time - t1) else 0;
end RandomLineaire;
