within ThermoSysPro.InstrumentationAndControl.Blocks.Discret;
block Echant
  parameter Real Gain=1 "Gain";
  parameter Real SampleOffset=0 "Instant de départ de l'échantillonnage (s)";
  parameter Real SampleInterval=0.01 "Période d'échantillonnage (s)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical continu annotation(Placement(transformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
protected
  Real uc;
  Real ud;
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Ellipse(extent={{-25,-10},{-45,10}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Ellipse(extent={{45,-10},{25,10}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(points={{-100,0},{-45,0}}, color={0,0,255}),Line(points={{45,0},{100,0}}, color={0,0,255}),Line(points={{-35,0},{30,35}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-25,-10},{-45,10}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Ellipse(extent={{45,-10},{25,10}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(points={{-100,0},{-45,0}}, color={0,0,255}),Line(points={{45,0},{100,0}}, color={0,0,255}),Line(points={{-35,0},{30,35}}, color={0,0,255}),Line(color={0,0,255}, points={{0,-20},{0,-100}}, pattern=LinePattern.Dot)}), Documentation(info="<html>
<p><b>Adapted from the ModelicaAdditions.Blocks.Discrete library</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
equation
  if cardinality(continu) == 0 then
    continu.signal=false;
  end if;
algorithm
  when {sample(SampleOffset, SampleInterval),not continu.signal} then
      ud:=u.signal;
  end when;
  uc:=u.signal;
  y.signal:=Gain*(if continu.signal then uc else ud);
end Echant;
