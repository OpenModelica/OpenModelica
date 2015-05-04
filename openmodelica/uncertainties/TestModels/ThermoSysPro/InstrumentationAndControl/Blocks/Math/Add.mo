within ThermoSysPro.InstrumentationAndControl.Blocks.Math;
block Add
  parameter Real k1=+1;
  parameter Real k2=+1;
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(color={0,0,255}, points={{80,0},{100,0}}),Ellipse(lineColor={0,0,255}, extent={{-80,80},{80,-80}}),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(color={0,0,255}, points={{-100,60},{-52,60}}),Line(color={0,0,255}, points={{-100,-60},{-52,-60}}),Text(lineColor={0,0,255}, extent={{-36,34},{40,-34}}, textString="+", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-96,94},{-56,64}}, textString="%k1", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-94,-66},{-54,-96}}, textString="%k2", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{50,0},{100,0}}),Line(color={0,0,255}, points={{50,0},{100,0}}),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(color={0,0,255}, points={{80,0},{100,0}}),Ellipse(lineColor={0,0,255}, extent={{-80,80},{80,-80}}),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(color={0,0,255}, points={{-100,60},{-52,60}}),Line(color={0,0,255}, points={{-100,-60},{-52,-60}}),Text(lineColor={0,0,255}, extent={{-36,34},{40,-34}}, textString="+", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-96,94},{-56,64}}, textString="k1", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-94,-66},{-54,-96}}, textString="k2", fillColor={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Math library</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u1 annotation(Placement(transformation(x=-110.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u2 annotation(Placement(transformation(x=-110.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  y.signal=k1*u1.signal + k2*u2.signal;
end Add;
