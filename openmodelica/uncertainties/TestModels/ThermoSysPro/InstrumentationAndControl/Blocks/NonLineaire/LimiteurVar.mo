within ThermoSysPro.InstrumentationAndControl.Blocks.NonLineaire;
block LimiteurVar
  parameter Real maxval=1 "Valeur maximale de la sortie si limit1 n'est pas connecté";
  parameter Real minval=-1 "Valeur minimale de la sortie si limit2 n'est pas connecté";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal limit1 annotation(Placement(transformation(x=-110.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal limit2 annotation(Placement(transformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputLogical ySMax annotation(Placement(transformation(x=110.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputLogical ySMin annotation(Placement(transformation(x=110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Real uMax;
  Real uMin;
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{78,60},{40,60},{-40,-60},{-80,-60}}, color={0,0,0}),Line(points={{-86,0},{88,0}}, color={192,192,192}),Polygon(points={{96,0},{86,-5},{86,5},{96,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Polygon(points={{0,84},{-5,74},{5,74},{0,84}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{0,-80},{0,74}}, color={192,192,192}),Line(color={0,0,255}, points={{-100,-80},{-60,-80},{-60,-66}}),Line(color={0,0,255}, points={{-100,80},{60,80},{60,64}}),Polygon(points={{-60,-62},{-65,-72},{-55,-72},{-60,-62}}, fillPattern=FillPattern.Solid, lineColor={0,127,255}, fillColor={0,127,255}),Polygon(lineColor={0,0,255}, points={{56,72},{64,72},{60,62},{56,72},{56,72}}, fillPattern=FillPattern.Solid, fillColor={0,127,255})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{26,90},{88,68}}, textString="umax", fillColor={160,160,160}),Text(lineColor={0,0,255}, extent={{-88,-64},{-26,-86}}, textString="umin", fillColor={160,160,160}),Line(points={{-86,0},{88,0}}, color={192,192,192}),Polygon(points={{96,0},{86,-5},{86,5},{96,0}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Polygon(points={{0,84},{-5,74},{5,74},{0,84}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{0,-80},{0,74}}, color={192,192,192}),Line(points={{78,60},{40,60},{-40,-60},{-80,-60}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.NonLinear library</b></p>
</HTML>
<html>
<p><b>Version 1.6</b></p>
</HTML>
"));
equation
  if cardinality(limit1) == 0 then
    limit1.signal=maxval;
  end if;
  if cardinality(limit2) == 0 then
    limit2.signal=minval;
  end if;
  uMax=max(limit1.signal, limit2.signal);
  uMin=min(limit1.signal, limit2.signal);
  y.signal=if u.signal > uMax then uMax else if u.signal < uMin then uMin else u.signal;
  ySMax.signal=u.signal >= uMax;
  ySMin.signal=u.signal <= uMin;
end LimiteurVar;
