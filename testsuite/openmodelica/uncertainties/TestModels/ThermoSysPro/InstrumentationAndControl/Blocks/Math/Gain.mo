within ThermoSysPro.InstrumentationAndControl.Blocks.Math;
block Gain
  parameter Real Gain=1 "Gain";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,100},{100,0},{-100,-100},{-100,100}}, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Text(lineColor={0,0,255}, extent={{-54,20},{-6,-16}}, textString="%Gain", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,100},{100,0},{-100,-100},{-100,100}}, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-54,20},{-6,-16}}, textString="Gain", fillColor={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Math library</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  y.signal=Gain*u.signal;
end Gain;
