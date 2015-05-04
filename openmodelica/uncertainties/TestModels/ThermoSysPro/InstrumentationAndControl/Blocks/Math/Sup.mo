within ThermoSysPro.InstrumentationAndControl.Blocks.Math;
block Sup
  parameter Real C1=0 "Valeur de u1 si u1 non connecté";
  parameter Real C2=0 "Valeur de u2 si u2 non connecté";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{80,0},{100,0}}),Ellipse(lineColor={0,0,255}, extent={{-80,80},{80,-80}}),Line(color={0,0,255}, points={{-100,60},{-52,60}}),Line(color={0,0,255}, points={{-100,-60},{-52,-60}}),Text(lineColor={0,0,255}, extent={{-36,34},{40,-34}}, textString=">", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-100,100},{-38,68}}, fillColor={0,0,255}, textString="C1"),Text(lineColor={0,0,255}, extent={{-100,-68},{-38,-100}}, fillColor={0,0,255}, textString="C2")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(color={0,0,255}, points={{80,0},{100,0}}),Ellipse(lineColor={0,0,255}, extent={{-80,80},{80,-80}}),Line(color={0,0,255}, points={{-100,60},{-52,60}}),Line(color={0,0,255}, points={{-100,-60},{-52,-60}}),Text(lineColor={0,0,255}, extent={{-36,34},{40,-34}}, textString=">", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-100,100},{-38,68}}, fillColor={0,0,255}, textString="C1"),Text(lineColor={0,0,255}, extent={{-100,-68},{-38,-100}}, fillColor={0,0,255}, textString="C2")}), Documentation(info="<html>
<p><b>Version 1.6</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u1 annotation(Placement(transformation(x=-110.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u2 annotation(Placement(transformation(x=-110.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputLogical yL annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(u1) == 0 then
    u1.signal=C1;
  end if;
  if cardinality(u2) == 0 then
    u2.signal=C2;
  end if;
  yL.signal=u1.signal > u2.signal;
end Sup;
