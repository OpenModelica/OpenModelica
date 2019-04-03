within ThermoSysPro.InstrumentationAndControl.Blocks.NonLineaire;
block SelecteurEntier "Sélection entre deux entiers"
  parameter Integer C1=-1 "Valeur de la sortie pour uCond=true si u1 non connecté";
  parameter Integer C2=1 "Valeur de la sortie pour uCond=false si u2 non connecté";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Line(points={{12,0},{100,0}}, color={0,0,0}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-40,80},{10,0}}, color={0,0,0}),Ellipse(extent={{2,8},{18,-8}}, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(points={{-40,70},{-40,80}}, color={0,0,0}),Line(points={{-40,80},{-30,76}}, color={0,0,0}),Line(points={{-100,0},{-40,0}}, color={0,0,0}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-98,-80},{-40,-80}}, color={0,0,0}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-98,80},{-40,80}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-100,80},{-38,48}}, fillColor={0,0,255}, textString="C1"),Text(lineColor={0,0,255}, extent={{-100,-48},{-38,-80}}, fillColor={0,0,255}, textString="C2"),Line(points={{-40,10},{-40,-10}}, color={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Line(points={{12,0},{100,0}}, color={0,0,0}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-40,10},{-40,-10}}, color={0,0,0}),Line(points={{-40,80},{10,0}}, color={0,0,0}),Ellipse(extent={{2,8},{18,-8}}, lineColor={160,160,160}, fillColor={160,160,160}, fillPattern=FillPattern.Solid),Line(points={{-40,70},{-40,80}}, color={0,0,0}),Line(points={{-40,80},{-30,76}}, color={0,0,0}),Line(points={{-100,0},{-40,0}}, color={0,0,0}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-98,-80},{-40,-80}}, color={0,0,0}, pattern=LinePattern.Solid, thickness=0.25, arrow={Arrow.None,Arrow.None}),Line(points={{-98,80},{-40,80}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-100,80},{-38,48}}, fillColor={0,0,255}, textString="C1"),Text(lineColor={0,0,255}, extent={{-100,-48},{-38,-80}}, fillColor={0,0,255}, textString="C2")}), Documentation(info="<html>
<p><b>Version 1.6</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical uCond annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OuputInteger y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputInteger u1 annotation(Placement(transformation(x=-110.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputInteger u2 annotation(Placement(transformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(u1) == 0 then
    u1.signal=C1;
  end if;
  if cardinality(u2) == 0 then
    u2.signal=C2;
  end if;
  y.signal=if uCond.signal then u1.signal else u2.signal;
end SelecteurEntier;
